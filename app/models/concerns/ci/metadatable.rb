# frozen_string_literal: true

module Ci
  ##
  # This module implements methods that need to read and write
  # metadata for CI/CD entities.
  #
  module Metadatable
    extend ActiveSupport::Concern
    include Gitlab::Utils::StrongMemoize

    included do
      has_one :metadata,
        ->(build) { where(partition_id: build.partition_id) },
        class_name: 'Ci::BuildMetadata',
        foreign_key: :build_id,
        partition_foreign_key: :partition_id,
        inverse_of: :build,
        autosave: true

      accepts_nested_attributes_for :metadata

      before_validation :ensure_metadata, on: :create, if: :can_write_metadata?

      scope :with_project_and_metadata, -> do
        preload(:project, :metadata, :job_definition)
      end

      def self.any_with_exposed_artifacts?
        found_exposed_artifacts = false

        includes(:job_definition).each_batch do |batch|
          # We only load what we need for `has_exposed_artifacts?`
          records = batch.select(:id, :partition_id, :project_id, :options).to_a

          ActiveRecord::Associations::Preloader.new(
            records: records,
            associations: :job_artifacts_metadata,
            scope: Ci::JobArtifact.select(:job_id, :partition_id, :exposed_as)
          ).call

          ActiveRecord::Associations::Preloader.new(
            records: records,
            associations: :metadata,
            scope: Ci::BuildMetadata.select(:build_id, :partition_id, :config_options)
          ).call

          next unless records.any?(&:has_exposed_artifacts?)

          found_exposed_artifacts = true
          break
        end

        found_exposed_artifacts
      end

      def self.select_with_exposed_artifacts
        includes(:metadata, :job_definition, :job_artifacts_metadata, :project).select(&:has_exposed_artifacts?)
      end
    end

    def has_exposed_artifacts?
      artifacts_exposed_as.present?
    end

    # Remove this method with FF `stop_writing_builds_metadata`
    def ensure_metadata
      metadata || build_metadata(project: project)
    end

    def degenerated?
      self.options.blank?
    end

    def degenerate!
      self.class.transaction do
        self.update!(options: nil, yaml_variables: nil)
        self.needs.all.delete_all
        self.metadata&.destroy
        self.job_definition_instance&.destroy
        yield if block_given?
      end
    end

    def options
      read_metadata_attribute(:options, :config_options, :options, {})
    end

    def yaml_variables
      read_metadata_attribute(:yaml_variables, :config_variables, :yaml_variables, [])
    end

    def options=(value)
      write_metadata_attribute(:options, :config_options, value)
    end

    def yaml_variables=(value)
      write_metadata_attribute(:yaml_variables, :config_variables, value)
    end

    def interruptible
      return job_definition.interruptible if read_from_new_destination? && job_definition

      metadata&.read_attribute(:interruptible)
    end

    def interruptible=(value)
      ensure_metadata.interruptible = value if can_write_metadata?
    end

    def id_tokens
      read_metadata_attribute(nil, :id_tokens, :id_tokens, {}).deep_stringify_keys
    end

    def id_tokens?
      id_tokens.present?
    end

    def id_tokens=(value)
      ensure_metadata.id_tokens = value if can_write_metadata?
    end

    def debug_trace_enabled?
      return debug_trace_enabled if read_from_new_destination? && !debug_trace_enabled.nil?
      return true if degenerated?

      !!metadata&.debug_trace_enabled?
    end

    def enable_debug_trace!
      update!(debug_trace_enabled: true)
      ensure_metadata.enable_debug_trace! if can_write_metadata?
    end

    def timeout_human_readable_value
      (read_from_new_destination? && timeout_human_readable) || metadata&.timeout_human_readable
    end

    def timeout_value
      (read_from_new_destination? && timeout) || metadata&.timeout
    end

    # This method is called from within a Ci::Build state transition;
    # it returns nil/true (success) or false (failure)
    def update_timeout_state
      timeout = ::Ci::Builds::TimeoutCalculator.new(self).applicable_timeout
      return unless timeout

      if can_write_metadata?
        success = ensure_metadata.update(timeout: timeout.value, timeout_source: timeout.source)
        return false unless success
      end

      # We don't use update because we're already in a Ci::Build transaction
      write_attribute(:timeout, timeout.value)
      write_attribute(:timeout_source, timeout.source)
      valid?
    end

    # metadata has `unknown_timeout_source` as default
    def timeout_source_value
      (read_from_new_destination? && timeout_source) || metadata&.timeout_source || 'unknown_timeout_source'
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
      (read_from_new_destination? && read_attribute(:scoped_user_id)) || options[:scoped_user_id]
    end

    def exit_code
      (read_from_new_destination? && read_attribute(:exit_code)) || metadata&.exit_code
    end

    def exit_code=(value)
      return unless value

      safe_value = value.to_i.clamp(0, Gitlab::Database::MAX_SMALLINT_VALUE)

      write_attribute(:exit_code, safe_value)
      ensure_metadata.exit_code = safe_value if can_write_metadata?
    end

    private

    def read_metadata_attribute(legacy_key, metadata_key, job_definition_key, default_value = nil)
      result = read_attribute(legacy_key) if legacy_key
      return result if result

      if read_from_new_destination?
        result = job_definition&.config&.dig(job_definition_key) || temp_job_definition&.config&.dig(job_definition_key)
        return result if result
      end

      metadata&.read_attribute(metadata_key) || default_value
    end

    def write_metadata_attribute(legacy_key, metadata_key, value)
      return unless can_write_metadata?

      ensure_metadata.write_attribute(metadata_key, value)
      write_attribute(legacy_key, nil)
    end

    def read_from_new_destination?
      Feature.enabled?(:read_from_new_ci_destinations, project)
    end
    strong_memoize_attr :read_from_new_destination?

    def can_write_metadata?
      Feature.disabled?(:stop_writing_builds_metadata, project)
    end
    strong_memoize_attr :can_write_metadata?
  end
end

Ci::Metadatable.prepend_mod_with('Ci::Metadatable')
