# frozen_string_literal: true

module Gitlab
  module Pages
    class DeploymentUpdate
      include ActiveModel::Validations

      PUBLIC_DIR = 'public'

      validate :validate_state, unless: -> { errors.any? }
      validate :validate_outdated_sha, unless: -> { errors.any? }
      validate :validate_max_size, unless: -> { errors.any? }
      validate :validate_public_folder, unless: -> { errors.any? }
      validate :validate_max_entries, unless: -> { errors.any? }

      def initialize(project, build)
        @project = project
        @build = build
      end

      def latest?
        # check if sha for the ref is still the most recent one
        # this helps in case when multiple deployments happens
        sha == latest_sha
      end

      def entries_count
        # we're using the full archive and pages daemon needs to read it
        # so we want the total count from entries, not only "public/" directory
        # because it better approximates work we need to do before we can serve the site
        @entries_count = build.artifacts_metadata_entry("", recursive: true).entries.count
      end

      private

      attr_reader :build, :project

      def validate_state
        errors.add(:base, 'missing pages artifacts') unless build.artifacts?
        errors.add(:base, 'missing artifacts metadata') unless build.artifacts_metadata?
      end

      def validate_max_size
        if total_size > max_size
          errors.add(:base, "artifacts for pages are too large: #{total_size}")
        end
      end

      def root_dir
        build.options[:publish] || PUBLIC_DIR
      end

      # Calculate page size after extract
      def total_size
        @total_size ||= build.artifacts_metadata_entry("#{root_dir}/", recursive: true).total_size
      end

      def max_size_from_settings
        Gitlab::CurrentSettings.max_pages_size.megabytes
      end

      def max_size
        max_pages_size = max_size_from_settings

        return ::Gitlab::Pages::MAX_SIZE if max_pages_size == 0

        max_pages_size
      end

      def validate_max_entries
        if pages_file_entries_limit > 0 && entries_count > pages_file_entries_limit
          errors.add(
            :base,
            "pages site contains #{entries_count} file entries, while limit is set to #{pages_file_entries_limit}"
          )
        end
      end

      def validate_public_folder
        if total_size <= 0
          errors.add(
            :base,
            'Error: You need to either include a `public/` folder in your artifacts, or specify ' \
            'which one to use for Pages using `publish` in `.gitlab-ci.yml`')
        end
      end

      def pages_file_entries_limit
        project.actual_limits.pages_file_entries
      end

      # If a newer pipeline already build a PagesDeployment
      def validate_outdated_sha
        return if latest?
        return if latest_pipeline_id.blank?
        return if latest_pipeline_id <= build.pipeline_id

        errors.add(:base, 'build SHA is outdated for this ref')
      end

      def latest_sha
        project.commit(build.ref).try(:sha).to_s
      ensure
        # Close any file descriptors that were opened and free libgit2 buffers
        project.cleanup
      end

      def sha
        build.sha
      end

      def latest_pipeline_id
        project
          .active_pages_deployments
          .with_path_prefix(build.pages&.dig(:path_prefix))
          .latest_pipeline_id
      end
    end
  end
end

Gitlab::Pages::DeploymentUpdate.prepend_mod_with('Gitlab::Pages::DeploymentUpdate')
