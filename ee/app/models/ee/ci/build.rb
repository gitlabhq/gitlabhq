module EE
  module Ci
    # Build EE mixin
    #
    # This module is intended to encapsulate EE-specific model logic
    # and be included in the `Build` model
    module Build
      extend ActiveSupport::Concern

      DEPENDENCY_SCANNING_FILE = 'gl-dependency-scanning-report.json'.freeze
      LICENSE_MANAGEMENT_FILE = 'gl-license-management-report.json'.freeze
      SAST_FILE = 'gl-sast-report.json'.freeze
      PERFORMANCE_FILE = 'performance.json'.freeze
      # SAST_CONTAINER_FILE is deprecated and replaced with CONTAINER_SCANNING_FILE (#5778)
      SAST_CONTAINER_FILE = 'gl-sast-container-report.json'.freeze
      CONTAINER_SCANNING_FILE = 'gl-container-scanning-report.json'.freeze
      DAST_FILE = 'gl-dast-report.json'.freeze

      prepended do
        after_save :stick_build_if_status_changed
      end

      def shared_runners_minutes_limit_enabled?
        runner && runner.instance_type? && project.shared_runners_minutes_limit_enabled?
      end

      def stick_build_if_status_changed
        return unless status_changed?
        return unless running?

        ::Gitlab::Database::LoadBalancing::Sticking.stick(:build, id)
      end

      def has_performance_json?
        name_in?(%w[performance deploy]) &&
          has_artifact?(PERFORMANCE_FILE)
      end

      def has_sast_json?
        name_in?('sast') &&
          has_artifact?(SAST_FILE)
      end

      def has_dependency_scanning_json?
        name_in?('dependency_scanning') &&
          has_artifact?(DEPENDENCY_SCANNING_FILE)
      end

      def has_license_management_json?
        name_in?('license_management') &&
          has_artifact?(LICENSE_MANAGEMENT_FILE)
      end

      # has_sast_container_json? is deprecated and replaced with has_container_scanning_json? (#5778)
      def has_sast_container_json?
        name_in?(%w[sast:container container_scanning]) &&
          has_artifact?(SAST_CONTAINER_FILE)
      end

      def has_container_scanning_json?
        name_in?(%w[sast:container container_scanning]) &&
          has_artifact?(CONTAINER_SCANNING_FILE)
      end

      def has_dast_json?
        name_in?('dast') &&
          has_artifact?(DAST_FILE)
      end

      def log_geo_deleted_event
        # It is not needed to generate a Geo deleted event
        # since Legacy Artifacts are migrated to multi-build artifacts
        # See https://gitlab.com/gitlab-org/gitlab-ce/issues/46652
      end

      def has_artifact?(name)
        options.dig(:artifacts, :paths)&.include?(name) &&
          artifacts_metadata?
      end

      private

      def name_in?(names)
        name.in?(Array(names))
      end
    end
  end
end
