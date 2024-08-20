# frozen_string_literal: true

module Gitlab
  module Octokit
    class UrlValidation
      def initialize(app)
        @app = app
      end

      def call(env)
        Gitlab::HTTP_V2::UrlBlocker.validate!(env[:url],
          schemes: %w[http https],
          allow_localhost: allow_local_requests?,
          allow_local_network: allow_local_requests?,
          dns_rebind_protection: dns_rebind_protection?,
          deny_all_requests_except_allowed: Gitlab::CurrentSettings.deny_all_requests_except_allowed?,
          outbound_local_requests_allowlist: Gitlab::CurrentSettings.outbound_local_requests_whitelist # rubocop:disable Naming/InclusiveLanguage -- existing setting
        )

        @app.call(env)
      end

      private

      def dns_rebind_protection?
        Gitlab::CurrentSettings.dns_rebinding_protection_enabled?
      end

      def allow_local_requests?
        Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
      end
    end
  end
end
