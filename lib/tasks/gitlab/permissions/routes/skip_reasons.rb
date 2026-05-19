# frozen_string_literal: true

module Tasks
  module Gitlab
    module Permissions
      module Routes
        module SkipReasons
          REASON_LABELS = {
            ai_workflows_oauth_auth: 'AI workflows OAuth token',
            compliance_external_auth: 'Compliance external control token',
            container_registry_event_auth: 'Container registry event token',
            error_tracking_token_auth: 'Error tracking token',
            geo_jwt_auth: 'Geo node JWT',
            geo_proxy_auth: 'Geo proxy',
            gitlab_shared_secret_auth: 'GitLab shared secret',
            gitlab_shell_token_auth: 'GitLab Shell token',
            internal_testing: 'Internal testing',
            job_token_auth: 'CI job token',
            kas_jwt_auth: 'Kubernetes agent JWT',
            mailroom_token_auth: 'Mailroom token',
            openbao_token_auth: 'OpenBao token',
            external_registry_redirect: 'External registry redirect',
            ai_workflows_token_auth: 'AI Workflows OAuth token',
            orbit_internal_auth: 'Orbit internal token',
            pages_token_auth: 'GitLab Pages token',
            public_endpoint: 'Public endpoint',
            runner_token_auth: 'Runner token',
            scim_token_auth: 'SCIM token',
            subscription_portal_jwt_auth: 'Subscription portal JWT',
            trigger_token_auth: 'CI trigger token',
            unleash_token_auth: 'Unleash token',
            usage_data_auth: 'Usage data token',
            workhorse_pre_authorization: 'Workhorse pre-authorization',
            workhorse_verification_auth: 'Workhorse verification'
          }.freeze

          VALID_SKIP_REASONS = REASON_LABELS.keys.freeze
        end
      end
    end
  end
end
