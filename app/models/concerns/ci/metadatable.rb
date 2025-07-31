# frozen_string_literal: true

module Ci
  ##
  # This module implements methods that need to read and write
  # metadata for CI/CD entities.
  #
  module Metadatable
    extend ActiveSupport::Concern

    included do
      has_one :metadata,
        ->(build) { where(partition_id: build.partition_id) },
        class_name: 'Ci::BuildMetadata',
        foreign_key: :build_id,
        partition_foreign_key: :partition_id,
        inverse_of: :build,
        autosave: true

      accepts_nested_attributes_for :metadata

      delegate :interruptible, to: :metadata, prefix: false, allow_nil: true
      delegate :id_tokens, to: :metadata, allow_nil: true
      delegate :exit_code, to: :metadata, allow_nil: true

      before_validation :ensure_metadata, on: :create

      scope :with_project_and_metadata, -> do
        joins(:metadata).includes(:metadata).preload(:project)
      end

      def self.any_with_exposed_artifacts?
        found_exposed_artifacts = false

        # TODO: Remove :project preload when FF `ci_use_job_artifacts_table_for_exposed_artifacts` is removed
        includes(:project).each_batch do |batch|
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
        includes(:metadata, :job_artifacts_metadata, :project).select(&:has_exposed_artifacts?)
      end
    end

    def has_exposed_artifacts?
      artifacts_exposed_as.present?
    end

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
        yield if block_given?
      end
    end

    def options
      read_metadata_attribute(:options, :config_options, {})
    end

    def yaml_variables
      read_metadata_attribute(:yaml_variables, :config_variables, [])
    end

    def options=(value)
      write_metadata_attribute(:options, :config_options, value)
    end

    def yaml_variables=(value)
      write_metadata_attribute(:yaml_variables, :config_variables, value)
    end

    def interruptible
      metadata&.interruptible
    end

    def interruptible=(value)
      ensure_metadata.interruptible = value
    end

    def id_tokens?
      metadata&.id_tokens.present?
    end

    def id_tokens=(value)
      ensure_metadata.id_tokens = value
    end

    # TODO: Update this logic when column `p_ci_builds.debug_trace_enabled` is added.
    # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194954#note_2574776849.
    def debug_trace_enabled?
      return true if degenerated?

      metadata&.debug_trace_enabled?
    end

    def timeout_value
      # TODO: need to add the timeout to p_ci_builds later
      # See https://gitlab.com/gitlab-org/gitlab/-/work_items/538183#note_2542611159
      try(:timeout) || metadata&.timeout
    end

    def artifacts_exposed_as
      if Feature.enabled?(:ci_use_job_artifacts_table_for_exposed_artifacts, project)
        job_artifacts_metadata&.exposed_as || options.dig(:artifacts, :expose_as)
      else
        options.dig(:artifacts, :expose_as)
      end
    end

    def artifacts_exposed_paths
      if Feature.enabled?(:ci_use_job_artifacts_table_for_exposed_artifacts, project)
        job_artifacts_metadata&.exposed_paths || artifacts_paths
      else
        artifacts_paths
      end
    end

    def artifacts_paths
      options.dig(:artifacts, :paths)
    end

    private

    def read_metadata_attribute(legacy_key, metadata_key, default_value = nil)
      read_attribute(legacy_key) || metadata&.read_attribute(metadata_key) || default_value
    end

    def write_metadata_attribute(legacy_key, metadata_key, value)
      ensure_metadata.write_attribute(metadata_key, value)
      write_attribute(legacy_key, nil)
    end
  end
end

Ci::Metadatable.prepend_mod_with('Ci::Metadatable')
