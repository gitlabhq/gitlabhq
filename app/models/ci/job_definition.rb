# frozen_string_literal: true

module Ci
  # The purpose of this class is to store immutable duplicate Processable related
  # data that can be disposed after all the pipelines that use it are archived.
  # Data that should be persisted forever, should be stored with Ci::Build model.
  class JobDefinition < Ci::ApplicationRecord
    include Ci::Partitionable
    include BulkInsertSafe

    self.table_name = :p_ci_job_definitions
    self.primary_key = :id

    # IMPORTANT: append new attributes at the end of this list. Do not change the order!
    # Order is important for the checksum calculation.
    # We have two constants at the moment because we'll only stop writing to the `p_ci_builds_metadata` table via
    # the `stop_writing_builds_metadata` feature flag. The `tag_list` and `run_steps` will be implemented in the future.
    CONFIG_ATTRIBUTES_FROM_METADATA = [
      :options,
      :yaml_variables,
      :id_tokens,
      :secrets,
      :interruptible
    ].freeze
    CONFIG_ATTRIBUTES = (CONFIG_ATTRIBUTES_FROM_METADATA + [:tag_list, :run_steps]).freeze
    NORMALIZED_DATA_COLUMNS = %i[interruptible].freeze

    # Partition ID from which we start using the new checksum approach on GitLab.com.
    # This is set to align with new partition creation to minimize redundant job definitions.
    # For context, see: https://gitlab.com/gitlab-org/gitlab/-/issues/577902
    NEW_CHECKSUM_PARTITION_THRESHOLD = 109

    query_constraints :id, :partition_id
    partitionable scope: ->(_) { Ci::Pipeline.current_partition_value }, partitioned: true

    belongs_to :project

    validates :project, presence: true
    validate :validate_config_json_schema

    attribute :config, ::Gitlab::Database::Type::SymbolizedJsonb.new

    scope :for_project, ->(project_id) { where(project_id: project_id) }
    scope :for_checksum, ->(checksum) { where(checksum: checksum) }
    scope :with_interruptible_true, -> { where(interruptible: true) }

    ignore_column :updated_at, remove_after: '2025-12-22', remove_with: '18.8'

    def self.fabricate(config:, project_id:, partition_id:)
      sanitized_config = sanitize_config(config)
      config_with_defaults = apply_normalized_defaults!(sanitized_config.deep_dup)

      if use_new_checksum_approach?(project_id, partition_id)
        # New approach: set defaults before checksum generation and remove normalized columns from config
        checksum = generate_checksum(config_with_defaults)
        persisted_config = sanitized_config.except(*NORMALIZED_DATA_COLUMNS)
      else
        # Old approach: generate checksum before setting defaults, persist original sanitized_config
        checksum = generate_checksum(sanitized_config)
        persisted_config = sanitized_config
      end

      new(
        project_id: project_id,
        partition_id: partition_id,
        config: persisted_config,
        checksum: checksum,
        created_at: Time.current,
        **config_with_defaults.slice(*NORMALIZED_DATA_COLUMNS)
      )
    end

    def self.sanitize_config(config)
      config
        .symbolize_keys
        .slice(*CONFIG_ATTRIBUTES)
        .then { |data| data.merge!(extract_and_parse_tags(data)) }
    end

    def self.generate_checksum(config)
      config
        .then { |data| Gitlab::Json.dump(data) }
        .then { |data| Digest::SHA256.hexdigest(data) }
    end

    def self.apply_normalized_defaults!(config)
      NORMALIZED_DATA_COLUMNS.each do |col|
        config[col] = config.fetch(col) { column_defaults[col.to_s] }
      end
      config
    end

    def self.use_new_checksum_approach?(project_id, partition_id)
      actor = Project.actor_from_id(project_id)
      return false unless Feature.enabled?(:ci_job_definitions_new_checksum, actor)

      partition_id ||= Ci::Partition.current&.id

      (partition_id && partition_id >= NEW_CHECKSUM_PARTITION_THRESHOLD) ||
        Feature.enabled?(:ci_job_definitions_force_new_checksum, actor)
    end

    def self.extract_and_parse_tags(config)
      tag_list = config[:tag_list]
      return {} unless tag_list

      { tag_list: Gitlab::Ci::Tags::Parser.new(tag_list).parse }
    end

    # We need to re-parse the tags because there are a few
    # records in the 106-107 partitions that were not properly
    # parsed during the pipeline creation.
    def tag_list
      tags = config.fetch(:tag_list) { [] }

      Gitlab::Ci::Tags::Parser.new(tags).parse
    end

    # Hash containing all job attributes: config + normalized_data.
    # Used in spec helpers, to merge with `job_attributes` instead of `config`.
    def job_attributes
      attributes.deep_symbolize_keys.slice(*NORMALIZED_DATA_COLUMNS).merge(config)
    end

    def readonly?
      persisted?
    end

    def validate_config_json_schema
      return if config.blank?

      validator = JsonSchemaValidator.new({
        filename: 'ci_job_definition_config',
        attributes: [:config],
        detail_errors: true
      })

      validator.validate(self)
      return if errors[:config].empty?

      Gitlab::AppJsonLogger.warn(
        class: self.class.name,
        message: 'Invalid config schema detected',
        job_definition_checksum: checksum,
        project_id: project_id,
        schema_errors: errors[:config]
      )

      errors.delete(:config) if Rails.env.production?
    end
  end
end
