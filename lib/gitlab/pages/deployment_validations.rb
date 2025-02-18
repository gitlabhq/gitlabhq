# frozen_string_literal: true

module Gitlab
  module Pages
    class DeploymentValidations
      include ActiveModel::Validations
      include ::Gitlab::Utils::StrongMemoize

      PUBLIC_DIR = 'public'

      with_options unless: -> { errors.any? } do
        validate :validate_state
        validate :validate_outdated_sha
        validate :validate_max_size
        validate :validate_public_folder
        validate :validate_max_entries
        validate :validate_pages_publish_options
      end

      def initialize(project, build)
        @project = project
        @build = build
      end

      def latest_build?
        # check if sha for the ref is still the most recent one
        # this helps in case when multiple deployments happens
        sha == latest_sha
      end

      def entries_count
        # we're using the full archive and pages daemon needs to read it
        # so we want the total count from entries, not only "public/" directory
        # because it better approximates work we need to do before we can serve the site
        build.artifacts_metadata_entry("", recursive: true).entries.count
      end
      strong_memoize_attr :entries_count

      private

      attr_reader :build, :project

      def validate_state
        errors.add(:base, 'missing pages artifacts') unless build.artifacts?
        errors.add(:base, 'missing artifacts metadata') unless build.artifacts_metadata?
      end

      def validate_max_size
        return if total_size <= max_size

        errors.add(:base, "artifacts for pages are too large: #{total_size}")
      end

      # Calculate page size after extract
      def total_size
        root_dir = build.pages[:publish] || PUBLIC_DIR

        build.artifacts_metadata_entry("#{root_dir}/", recursive: true).total_size
      end

      def max_size
        max_pages_size = max_size_from_settings

        return ::Gitlab::Pages::MAX_SIZE if max_pages_size == 0

        max_pages_size
      end

      def validate_max_entries
        pages_file_entries_limit = project.actual_limits.pages_file_entries
        return unless pages_file_entries_limit > 0 && entries_count > pages_file_entries_limit

        errors.add(
          :base,
          "pages site contains #{entries_count} file entries, while limit is set to #{pages_file_entries_limit}"
        )
      end

      def validate_public_folder
        return if total_size > 0

        errors.add(
          :base,
          'Error: You need to either include a `public/` folder in your artifacts, or specify ' \
          'which one to use for Pages using `publish` in `.gitlab-ci.yml`')
      end

      # If a newer pipeline already build a PagesDeployment
      def validate_outdated_sha
        return if latest_build?
        return if latest_pipeline_id.blank?
        return if latest_pipeline_id <= build.pipeline_id

        errors.add(:base, 'build SHA is outdated for this ref')
      end

      def validate_pages_publish_options
        return unless build.options.present?
        return unless build.options[:pages].is_a?(Hash)
        return unless build.options.key?(:publish) && build.options[:pages]&.key?(:publish)

        errors.add(
          :base,
          _("Either the `publish` or `pages.publish` option may be present in `.gitlab-ci.yml`, but not both."))
      end

      def latest_sha
        project.commit(build.ref).try(:sha).to_s
      ensure
        # Close any file descriptors that were opened and free libgit2 buffers
        project.cleanup
      end

      def latest_pipeline_id
        project
          .active_pages_deployments
          .with_path_prefix(path_prefix)
          .latest_pipeline_id
      end

      # overridden in EE
      def max_size_from_settings = Gitlab::CurrentSettings.max_pages_size.megabytes

      def path_prefix = build.pages&.fetch(:path_prefix, '')
      strong_memoize_attr :path_prefix

      def sha = build.sha
      strong_memoize_attr :sha
    end
  end
end

Gitlab::Pages::DeploymentValidations.prepend_mod_with('Gitlab::Pages::DeploymentValidations')
