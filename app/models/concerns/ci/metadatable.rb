# frozen_string_literal: true

module Ci
  ##
  # This module implements methods that expose CI/CD processable configuration.
  #
  module Metadatable
    extend ActiveSupport::Concern
    include Gitlab::Utils::StrongMemoize

    included do
      scope :with_project_and_job_definition, -> do
        preload(:project, :job_definition)
      end

      def self.any_with_exposed_artifacts?
        found_exposed_artifacts = false

        includes(:job_definition).each_batch do |batch|
          # We only load what we need for `has_exposed_artifacts?`
          records = batch.select(:id, :partition_id, :project_id).to_a

          ActiveRecord::Associations::Preloader.new(
            records: records,
            associations: :job_artifacts_metadata,
            scope: Ci::JobArtifact.select(:job_id, :partition_id, :exposed_as)
          ).call

          next unless records.any?(&:has_exposed_artifacts?)

          found_exposed_artifacts = true
          break
        end

        found_exposed_artifacts
      end

      def self.select_with_exposed_artifacts
        includes(:job_definition, :job_artifacts_metadata, :project).select(&:has_exposed_artifacts?)
      end
    end

    def has_exposed_artifacts?
      artifacts_exposed_as.present?
    end

    def degenerated?
      self.options.blank?
    end

    def degenerate!
      self.class.transaction do
        self.needs.all.delete_all
        self.job_definition_instance&.destroy
        yield if block_given?
      end
    end

    def options
      read_job_definition_attribute(:options, {})
    end

    def yaml_variables
      read_job_definition_attribute(:yaml_variables, [])
    end

    def interruptible
      read_job_definition_attribute(:interruptible, false)
    end

    def id_tokens
      read_job_definition_attribute(:id_tokens, {}).deep_stringify_keys
    end

    def id_tokens?
      id_tokens.present?
    end

    def debug_trace_enabled?
      return debug_trace_enabled unless debug_trace_enabled.nil?

      degenerated?
    end

    def enable_debug_trace!
      update!(debug_trace_enabled: true)
    end

    def timeout_human_readable_value
      timeout_human_readable
    end

    def timeout_value
      timeout
    end

    # This method is called from within a Ci::Build state transition;
    # it returns nil/true (success) or false (failure)
    def update_timeout_state
      timeout = ::Ci::Builds::TimeoutCalculator.new(self).applicable_timeout
      return unless timeout

      # We don't use update because we're already in a Ci::Build transaction
      write_attribute(:timeout, timeout.value)
      write_attribute(:timeout_source, timeout.source)
      valid?
    end

    def timeout_source_value
      timeout_source || 'unknown_timeout_source'
    end

    def artifacts_exposed_as
      job_artifacts_metadata&.exposed_as || options.dig(:artifacts, :expose_as)
    end

    def artifacts_exposed_paths
      job_artifacts_metadata&.exposed_paths || options.dig(:artifacts, :paths)
    end

    def downstream_errors
      error_job_messages.map(&:content).presence || options[:downstream_errors]
    end
    strong_memoize_attr :downstream_errors

    def scoped_user_id
      read_attribute(:scoped_user_id) || options[:scoped_user_id]
    end

    def exit_code=(value)
      return unless value

      safe_value = value.to_i.clamp(0, Gitlab::Database::MAX_SMALLINT_VALUE)

      write_attribute(:exit_code, safe_value)
    end

    def interruptible=(_value)
      raise ActiveRecord::ReadonlyAttributeError, 'This data is read only'
    end

    def id_tokens=(_value)
      raise ActiveRecord::ReadonlyAttributeError, 'This data is read only'
    end

    def secrets=(_value)
      raise ActiveRecord::ReadonlyAttributeError, 'This data is read only'
    end

    private

    def read_job_definition_attribute(key, default_value = nil)
      result =
        if key.in?(::Ci::JobDefinition::NORMALIZED_DATA_COLUMNS)
          [job_definition&.read_attribute(key), temp_job_definition&.read_attribute(key)].find { |value| !value.nil? }
        else
          [job_definition&.config&.dig(key), temp_job_definition&.config&.dig(key)].find { |value| !value.nil? }
        end

      # Only nil falls back; false is a valid value for normalized columns.
      result.nil? ? default_value : result
    end
  end
end

Ci::Metadatable.prepend_mod_with('Ci::Metadatable')
