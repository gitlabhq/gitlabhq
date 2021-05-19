# frozen_string_literal: true

module Gitlab
  module RackAttack
    module Request
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

      def throttle_unauthenticated?
        !should_be_skipped? &&
        !throttle_unauthenticated_packages_api? &&
        Gitlab::Throttle.settings.throttle_unauthenticated_enabled &&
        unauthenticated?
      end

      def throttle_authenticated_api?
        api_request? &&
        !throttle_authenticated_packages_api? &&
        Gitlab::Throttle.settings.throttle_authenticated_api_enabled
      end

      def throttle_authenticated_web?
        web_request? &&
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
    end
  end
end
::Gitlab::RackAttack::Request.prepend_mod_with('Gitlab::RackAttack::Request')
