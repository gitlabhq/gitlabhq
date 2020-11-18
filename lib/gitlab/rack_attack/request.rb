# frozen_string_literal: true

module Gitlab
  module RackAttack
    module Request
      def unauthenticated?
        !(authenticated_user_id([:api, :rss, :ics]) || authenticated_runner_id)
      end

      def authenticated_user_id(request_formats)
        request_authenticator.user(request_formats)&.id
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

      def product_analytics_collector_request?
        path.start_with?('/-/collector/i')
      end

      def should_be_skipped?
        api_internal_request? || health_check_request?
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

      private

      def request_authenticator
        @request_authenticator ||= Gitlab::Auth::RequestAuthenticator.new(self)
      end

      def protected_paths
        Gitlab::CurrentSettings.current_application_settings.protected_paths
      end

      def protected_paths_regex
        Regexp.union(protected_paths.map { |path| /\A#{Regexp.escape(path)}/ })
      end
    end
  end
end
::Gitlab::RackAttack::Request.prepend_if_ee('::EE::Gitlab::RackAttack::Request')
