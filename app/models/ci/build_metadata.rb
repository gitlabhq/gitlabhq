# frozen_string_literal: true

module Ci
  # The purpose of this class is to store Build related data that can be disposed.
  # Data that should be persisted forever, should be stored with Ci::Build model.
  class BuildMetadata < Ci::ApplicationRecord
    include Ci::Partitionable
    include Presentable
    include ChronicDurationAttribute
    include Gitlab::Utils::StrongMemoize

    self.table_name = 'p_ci_builds_metadata'
    self.primary_key = 'id'

    query_constraints :id, :partition_id
    partitionable scope: :build, partitioned: true

    belongs_to :build, # rubocop: disable Rails/InverseOf -- this relation is not present on CommitStatus
      ->(metadata) { in_partition(metadata) },
      partition_foreign_key: :partition_id,
      class_name: 'CommitStatus'

    belongs_to :project

    before_create :set_build_project

    validates :build, presence: true
    validates :id_tokens, json_schema: { filename: 'build_metadata_id_tokens' }
    validates :secrets, json_schema: { filename: 'build_metadata_secrets' }
    validate :validate_config_options_schema

    attribute :config_options, ::Gitlab::Database::Type::SymbolizedJsonb.new
    attribute :config_variables, ::Gitlab::Database::Type::SymbolizedJsonb.new

    chronic_duration_attr_reader :timeout_human_readable, :timeout

    scope :scoped_build, -> do
      where(arel_table[:build_id].eq(Ci::Build.arel_table[:id]))
      .where(arel_table[:partition_id].eq(Ci::Build.arel_table[:partition_id]))
    end

    scope :with_interruptible, -> { where(interruptible: true) }

    enum :timeout_source, {
      unknown_timeout_source: 1,
      project_timeout_source: 2,
      runner_timeout_source: 3,
      job_timeout_source: 4
    }

    def update_timeout_state
      timeout = ::Ci::Builds::TimeoutCalculator.new(build).applicable_timeout
      return unless timeout

      update(timeout: timeout.value, timeout_source: timeout.source)
    end

    def enable_debug_trace!
      self.debug_trace_enabled = true
      save! if changes.any?
      true
    end

    private

    def set_build_project
      self.project_id ||= build.project_id
    end

    def ci_validate_config_options_enabled?
      Feature.enabled?(:ci_validate_config_options, project)
    end

    def validate_config_options_schema
      return unless ci_validate_config_options_enabled?

      validator = JsonSchemaValidator.new({
        filename: 'build_metadata_config_options',
        attributes: [:config_options],
        detail_errors: true
      })

      validator.validate(self)
      return if errors[:config_options].empty?

      Gitlab::AppJsonLogger.warn(
        class: self.class.name,
        message: 'Invalid config_options schema detected',
        build_metadata_id: id,
        project_id: project_id,
        schema_errors: errors[:config_options]
      )

      errors.delete(:config_options) if Rails.env.production?
    end
  end
end
