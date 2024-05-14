# frozen_string_literal: true

module Gitlab
  module RackAttack
    module Request
      include ::Gitlab::Utils::StrongMemoize

      API_PATH_REGEX = %r{^/api/|/oauth/}
      FILES_PATH_REGEX = %r{^/api/v\d+/projects/[^/]+/repository/files/.+}
      GROUP_PATH_REGEX = %r{^/api/v\d+/groups/[^/]+/?$}

      def unauthenticated?
        !(authenticated_identifier([:api, :rss, :ics]) || authenticated_runner_id)
      end

      def throttled_identifer(request_formats)
        identifier = authenticated_identifier(request_formats)
        return unless identifier

        identifier_type = identifier[:identifier_type]
        identifier_id = identifier[:identifier_id]

        if identifier_type == :user && Gitlab::RackAttack.user_allowlist.include?(identifier_id)
          Gitlab::Instrumentation::Throttle.safelist = 'throttle_user_allowlist'
          return
        end

        "#{identifier_type}:#{identifier_id}"
      end

      def authenticated_runner_id
        request_authenticator.runner&.id
      end

      def api_request?
        matches?(API_PATH_REGEX)
      end

      def logical_path
        @logical_path ||= path.delete_prefix(Gitlab.config.gitlab.relative_url_root)
      end

      def matches?(regex)
        logical_path.match?(regex)
      end

      def api_internal_request?
        matches?(%r{^/api/v\d+/internal/})
      end

      def health_check_request?
        matches?(%r{^/-/(health|liveness|readiness|metrics)})
      end

      def container_registry_event?
        matches?(%r{^/api/v\d+/container_registry_event/})
      end

      def product_analytics_collector_request?
        logical_path.start_with?('/-/collector/i')
      end

      def should_be_skipped?
        api_internal_request? || health_check_request? || container_registry_event?
      end

      def web_request?
        !api_request? && !health_check_request?
      end

      def protected_path?
        matches?(protected_paths_regex)
      end

      def get_request_protected_path?
        matches?(protected_paths_for_get_request_regex)
      end

      def throttle?(throttle, authenticated:)
        fragment = Gitlab::Throttle.throttle_fragment!(throttle, authenticated: authenticated)

        __send__("#{fragment}?") # rubocop:disable GitlabSecurity/PublicSend
      end

      def throttle_unauthenticated_api?
        api_request? &&
          !should_be_skipped? &&
          !frontend_request? &&
          !throttle_unauthenticated_packages_api? &&
          !throttle_unauthenticated_files_api? &&
          !throttle_unauthenticated_deprecated_api? &&
          Gitlab::Throttle.settings.throttle_unauthenticated_api_enabled &&
          unauthenticated?
      end

      def throttle_unauthenticated_web?
        (web_request? || frontend_request?) &&
          !should_be_skipped? &&
          !git_path? &&
          # TODO: Column will be renamed in https://gitlab.com/gitlab-org/gitlab/-/issues/340031
          Gitlab::Throttle.settings.throttle_unauthenticated_enabled &&
          unauthenticated?
      end

      def throttle_authenticated_api?
        api_request? &&
          !frontend_request? &&
          !throttle_authenticated_packages_api? &&
          !throttle_authenticated_files_api? &&
          !throttle_authenticated_deprecated_api? &&
          Gitlab::Throttle.settings.throttle_authenticated_api_enabled
      end

      def throttle_authenticated_web?
        (web_request? || frontend_request?) &&
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

      def throttle_unauthenticated_get_protected_paths?
        get? &&
          !should_be_skipped? &&
          get_request_protected_path? &&
          Gitlab::Throttle.protected_paths_enabled? &&
          unauthenticated?
      end

      def throttle_authenticated_get_protected_paths_api?
        get? &&
          api_request? &&
          get_request_protected_path? &&
          Gitlab::Throttle.protected_paths_enabled?
      end

      def throttle_authenticated_get_protected_paths_web?
        get? &&
          web_request? &&
          get_request_protected_path? &&
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

      def throttle_unauthenticated_git_http?
        git_path? &&
          Gitlab::Throttle.settings.throttle_unauthenticated_git_http_enabled &&
          unauthenticated?
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

      def authenticated_identifier(request_formats)
        requester = request_authenticator.find_authenticated_requester(request_formats)

        return unless requester

        identifier_type = if requester.is_a?(DeployToken)
                            :deploy_token
                          else
                            :user
                          end

        { identifier_type: identifier_type, identifier_id: requester.id }
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

      def protected_paths_for_get_request
        Gitlab::CurrentSettings.current_application_settings.protected_paths_for_get_request
      end

      def protected_paths_for_get_request_regex
        Regexp.union(protected_paths_for_get_request.map { |path| /\A#{Regexp.escape(path)}/ })
      end

      def packages_api_path?
        matches?(::Gitlab::Regex::Packages::API_PATH_REGEX)
      end

      def git_path?
        matches?(::Gitlab::PathRegex.repository_git_route_regex)
      end

      def git_lfs_path?
        matches?(::Gitlab::PathRegex.repository_git_lfs_route_regex)
      end

      def files_api_path?
        matches?(FILES_PATH_REGEX)
      end

      def frontend_request?
        strong_memoize(:frontend_request) do
          next false unless env.include?('HTTP_X_CSRF_TOKEN') && session.include?(:_csrf_token)

          # CSRF tokens are not verified for GET/HEAD requests, so we pretend that we always have a POST request.
          Gitlab::RequestForgeryProtection.verified?(env.merge('REQUEST_METHOD' => 'POST'))
        end
      end

      def deprecated_api_request?
        # The projects member of the groups endpoint is deprecated. If left
        # unspecified, with_projects defaults to true
        with_projects = params['with_projects']
        with_projects = true if with_projects.blank?

        matches?(GROUP_PATH_REGEX) && Gitlab::Utils.to_boolean(with_projects)
      end
    end
  end
end
::Gitlab::RackAttack::Request.prepend_mod_with('Gitlab::RackAttack::Request')
