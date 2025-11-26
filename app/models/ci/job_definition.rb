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
      sanitized_config, checksum = sanitize_and_checksum(config)

      attrs = {
        project_id: project_id,
        partition_id: partition_id,
        config: sanitized_config,
        checksum: checksum,
        created_at: Time.current
      }

      NORMALIZED_DATA_COLUMNS.each do |col|
        attrs[col] = sanitized_config.fetch(col) { column_defaults[col.to_s] }
      end

      new(attrs)
    end

    def self.sanitize_and_checksum(config)
      sanitized_config = config
        .symbolize_keys
        .slice(*CONFIG_ATTRIBUTES)
        .then { |data| data.merge!(extract_and_parse_tags(data)) }

      checksum = sanitized_config
        .then { |data| Gitlab::Json.dump(data) }
        .then { |data| Digest::SHA256.hexdigest(data) }

      [sanitized_config, checksum]
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
