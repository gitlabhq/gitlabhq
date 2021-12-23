# frozen_string_literal: true

module Gitlab
  module RackAttack
    module Request
      FILES_PATH_REGEX = %r{^/api/v\d+/projects/[^/]+/repository/files/.+}.freeze
      GROUP_PATH_REGEX = %r{^/api/v\d+/groups/[^/]+/?$}.freeze

      def unauthenticated?
        !(authenticated_user_id([:api, :rss, :ics]) || authenticated_runner_id)
      end

      def throttled_user_id(request_formats)
        user_id = authenticated_user_id(request_formats)

        if Gitlab::RackAttack.user_allowlist.include?(user_id)
          Gitlab::Instrumentation::Throttle.safelist = 'throttle_user_allowlist'
          return
        end

        user_id
      end

      def authenticated_runner_id
        request_authenticator.runner&.id
      end

      def api_request?
        path.start_with?('/api')
      end

      def api_internal_request?
        path =~ %r{^/api/v\d+/internal/}
      end

      def health_check_request?
        path =~ %r{^/-/(health|liveness|readiness|metrics)}
      end

      def container_registry_event?
        path =~ %r{^/api/v\d+/container_registry_event/}
      end

      def product_analytics_collector_request?
        path.start_with?('/-/collector/i')
      end

      def should_be_skipped?
        api_internal_request? || health_check_request? || container_registry_event?
      end

      def web_request?
        !api_request? && !health_check_request?
      end

      def protected_path?
        !protected_path_regex.nil?
      end

      def protected_path_regex
        path =~ protected_paths_regex
      end

      def throttle?(throttle, authenticated:)
        fragment = Gitlab::Throttle.throttle_fragment!(throttle, authenticated: authenticated)

        __send__("#{fragment}?") # rubocop:disable GitlabSecurity/PublicSend
      end

      def throttle_unauthenticated_api?
        api_request? &&
        !should_be_skipped? &&
        !throttle_unauthenticated_packages_api? &&
        !throttle_unauthenticated_files_api? &&
        !throttle_unauthenticated_deprecated_api? &&
        Gitlab::Throttle.settings.throttle_unauthenticated_api_enabled &&
        unauthenticated?
      end

      def throttle_unauthenticated_web?
        web_request? &&
        !should_be_skipped? &&
        # TODO: Column will be renamed in https://gitlab.com/gitlab-org/gitlab/-/issues/340031
        Gitlab::Throttle.settings.throttle_unauthenticated_enabled &&
        unauthenticated?
      end

      def throttle_authenticated_api?
        api_request? &&
        !throttle_authenticated_packages_api? &&
        !throttle_authenticated_files_api? &&
        !throttle_authenticated_deprecated_api? &&
        Gitlab::Throttle.settings.throttle_authenticated_api_enabled
      end

      def throttle_authenticated_web?
        web_request? &&
        !throttle_authenticated_git_lfs? &&
        Gitlab::Throttle.settings.throttle_authenticated_web_enabled
      end

      def throttle_unauthenticated_protected_paths?
        post? &&
        !should_be_skipped? &&
        protected_path? &&
        Gitlab::Throttle.protected_paths_enabled? &&
        unauthenticated?
      end

      def throttle_authenticated_protected_paths_api?
        post? &&
        api_request? &&
        protected_path? &&
        Gitlab::Throttle.protected_paths_enabled?
      end

      def throttle_authenticated_protected_paths_web?
        post? &&
        web_request? &&
        protected_path? &&
        Gitlab::Throttle.protected_paths_enabled?
      end

      def throttle_unauthenticated_packages_api?
        packages_api_path? &&
        Gitlab::Throttle.settings.throttle_unauthenticated_packages_api_enabled &&
        unauthenticated?
      end

      def throttle_authenticated_packages_api?
        packages_api_path? &&
        Gitlab::Throttle.settings.throttle_authenticated_packages_api_enabled
      end

      def throttle_authenticated_git_lfs?
        git_lfs_path? &&
        Gitlab::Throttle.settings.throttle_authenticated_git_lfs_enabled
      end

      def throttle_unauthenticated_files_api?
        files_api_path? &&
        Gitlab::Throttle.settings.throttle_unauthenticated_files_api_enabled &&
        unauthenticated?
      end

      def throttle_authenticated_files_api?
        files_api_path? &&
        Gitlab::Throttle.settings.throttle_authenticated_files_api_enabled
      end

      def throttle_unauthenticated_deprecated_api?
        deprecated_api_request? &&
        Gitlab::Throttle.settings.throttle_unauthenticated_deprecated_api_enabled &&
        unauthenticated?
      end

      def throttle_authenticated_deprecated_api?
        deprecated_api_request? &&
        Gitlab::Throttle.settings.throttle_authenticated_deprecated_api_enabled
      end

      private

      def authenticated_user_id(request_formats)
        request_authenticator.user(request_formats)&.id
      end

      def request_authenticator
        @request_authenticator ||= Gitlab::Auth::RequestAuthenticator.new(self)
      end

      def protected_paths
        Gitlab::CurrentSettings.current_application_settings.protected_paths
      end

      def protected_paths_regex
        Regexp.union(protected_paths.map { |path| /\A#{Regexp.escape(path)}/ })
      end

      def packages_api_path?
        path =~ ::Gitlab::Regex::Packages::API_PATH_REGEX
      end

      def git_lfs_path?
        path =~ Gitlab::PathRegex.repository_git_lfs_route_regex
      end

      def files_api_path?
        path =~ FILES_PATH_REGEX
      end

      def deprecated_api_request?
        # The projects member of the groups endpoint is deprecated. If left
        # unspecified, with_projects defaults to true
        with_projects = params['with_projects']
        with_projects = true if with_projects.blank?

        path =~ GROUP_PATH_REGEX && Gitlab::Utils.to_boolean(with_projects)
      end
    end
  end
end
::Gitlab::RackAttack::Request.prepend_mod_with('Gitlab::RackAttack::Request')
