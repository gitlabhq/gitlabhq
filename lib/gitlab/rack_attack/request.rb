# frozen_string_literal: true

module Gitlab
  module RackAttack
    # The legacy Rack::Attack throttle predicates, mixed into Rack::Attack::Request
    # (see Gitlab::RackAttack.configure). The request-classification primitives
    # these build on live in Gitlab::RateLimit::RequestClassification, shared with
    # the Labkit rate-limit stack that has replaced Rack::Attack as the enforcer.
    module Request
      include ::Gitlab::RateLimit::RequestClassification

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

      def should_be_skipped?
        api_internal_request? || health_check_request? || container_registry_event?
      end

      def protected_path?
        matches_protected_path?(protected_paths)
      end

      def get_request_protected_path?
        matches_protected_path?(protected_paths_for_get_request)
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
          !runner_jobs_request? &&
          !throttle_authenticated_packages_api? &&
          !throttle_authenticated_files_api? &&
          !throttle_authenticated_deprecated_api? &&
          Gitlab::Throttle.settings.throttle_authenticated_api_enabled
      end

      def throttle_authenticated_web?
        (web_request? || frontend_request?) &&
          !throttle_authenticated_git_lfs? &&
          !(git_path? && !git_lfs_path?) &&
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

      def throttle_authenticated_git_http?
        git_path? && !git_lfs_path? &&
          Gitlab::Throttle.settings.throttle_authenticated_git_http_enabled
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

      def runner_jobs_request?
        runner_jobs_api_path? &&
          (request_authenticator.runner.present? || request_authenticator.job_from_token.present?)
      end
    end
  end
end
::Gitlab::RackAttack::Request.prepend_mod_with('Gitlab::RackAttack::Request')
