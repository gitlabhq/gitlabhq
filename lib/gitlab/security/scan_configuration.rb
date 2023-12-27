# frozen_string_literal: true

module Gitlab
  module Security
    class ScanConfiguration
      include ::Gitlab::Utils::StrongMemoize
      include Gitlab::Routing.url_helpers

      attr_reader :type

      def initialize(project:, type:, configured: false)
        @project = project
        @type = type
        @configured = configured
      end

      def available?
        # SAST and Secret Detection are always available, but this isn't
        # reflected by our license model yet.
        # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/333113
        %i[sast sast_iac secret_detection container_scanning].include?(type)
      end

      def can_enable_by_merge_request?
        scans_configurable_in_merge_request.include?(type)
      end

      def configured?
        configured
      end

      def configuration_path; end

      def meta_info_path; end

      def on_demand_available?
        false
      end

      def security_features
        Features.data[type] || {}
      end

      private

      attr_reader :project, :configured

      def scans_configurable_in_merge_request
        %i[sast sast_iac secret_detection]
      end
    end
  end
end

Gitlab::Security::ScanConfiguration.prepend_mod_with('Gitlab::Security::ScanConfiguration')
