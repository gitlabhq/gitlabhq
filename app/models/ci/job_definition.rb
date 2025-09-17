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

    query_constraints :id, :partition_id
    partitionable scope: ->(_) { Ci::Pipeline.current_partition_value }, partitioned: true

    belongs_to :project

    validates :project, presence: true

    # rubocop:disable Database/JsonbSizeLimit -- no updates
    validates :config, json_schema: { filename: 'ci_job_definitions_config' }
    # rubocop:enable Database/JsonbSizeLimit

    attribute :config, ::Gitlab::Database::Type::SymbolizedJsonb.new

    scope :for_project, ->(project_id) { where(project_id: project_id) }
    scope :for_checksum, ->(checksum) { where(checksum: checksum) }
    scope :with_interruptible_true, -> { where(interruptible: true) }

    def self.fabricate(config:, project_id:, partition_id:)
      sanitized_config, checksum = sanitize_and_checksum(config)

      current_time = Time.current

      new(
        project_id: project_id,
        partition_id: partition_id,
        config: sanitized_config,
        checksum: checksum,
        interruptible: sanitized_config.fetch(:interruptible) { column_defaults['interruptible'] },
        created_at: current_time,
        updated_at: current_time
      )
    end

    def self.sanitize_and_checksum(config)
      sanitized_config = config.symbolize_keys.slice(*CONFIG_ATTRIBUTES)

      checksum = sanitized_config
        .then { |data| Gitlab::Json.dump(data) }
        .then { |data| Digest::SHA256.hexdigest(data) }

      [sanitized_config, checksum]
    end

    def readonly?
      persisted?
    end
  end
end
