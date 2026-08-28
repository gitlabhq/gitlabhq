# frozen_string_literal: true

module Gitlab
  module RateLimit
    # Request-classification primitives shared by the Labkit rate-limit stack
    # (ClassifiedRequest, ThrottleRegistry) and, until its removal, the legacy
    # Gitlab::RackAttack::Request throttle predicates. Mix into a Rack::Request.
    module RequestClassification
      include ::Gitlab::Utils::StrongMemoize

      API_PATH_REGEX = %r{^/api/|/oauth/}
      FILES_PATH_REGEX = %r{^/api/v\d+/projects/[^/]+/repository/files/.+}
      GROUP_PATH_REGEX = %r{^/api/v\d+/groups/[^/]+/?$}
      RUNNER_JOBS_PATH_REGEX = %r{^/api/v\d+/jobs/}
      API_INTERNAL_PATH_REGEX = %r{^/api/v\d+/internal/}
      HEALTH_CHECK_PATH_REGEX = %r{^/-/(health|liveness|readiness|metrics)}
      CONTAINER_REGISTRY_EVENT_PATH_REGEX = %r{^/api/v\d+/container_registry_event/}

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
        matches?(API_INTERNAL_PATH_REGEX)
      end

      def health_check_request?
        matches?(HEALTH_CHECK_PATH_REGEX)
      end

      def container_registry_event?
        matches?(CONTAINER_REGISTRY_EVENT_PATH_REGEX)
      end

      def product_analytics_collector_request?
        logical_path.start_with?('/-/collector/i')
      end

      def web_request?
        !api_request? && !health_check_request? && !product_analytics_collector_request?
      end

      private

      def runner_jobs_api_path?
        matches?(RUNNER_JOBS_PATH_REGEX)
      end

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

      def protected_paths_for_get_request
        Gitlab::CurrentSettings.current_application_settings.protected_paths_for_get_request
      end

      def matches_protected_path?(paths)
        if logical_path.start_with?('/o/')
          matches?(org_scoped_paths_regex(paths))
        else
          matches?(paths_regex(paths))
        end
      end

      def paths_regex(paths)
        Regexp.union(paths.map { |path| /\A#{Regexp.escape(path)}/ })
      end

      def org_scoped_paths_regex(paths)
        Regexp.union(paths.map { |path| %r{\A/o/[^/]+#{Regexp.escape(path)}} })
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
        return false unless env.include?('HTTP_X_CSRF_TOKEN') && session.include?(:_csrf_token)

        # CSRF tokens are not verified for GET/HEAD requests, so we pretend that we always have a POST request.
        Gitlab::RequestForgeryProtection.verified?(env.merge('REQUEST_METHOD' => 'POST'))
      end
      strong_memoize_attr :frontend_request?

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

::Gitlab::RateLimit::RequestClassification.prepend_mod
