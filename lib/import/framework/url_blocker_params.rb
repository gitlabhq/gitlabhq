# frozen_string_literal: true

module Import
  module Framework
    class UrlBlockerParams
      def to_h
        {
          allow_localhost: allow_local_requests?,
          allow_local_network: allow_local_requests?,
          schemes: %w[http https],
          deny_all_requests_except_allowed: Gitlab::CurrentSettings.deny_all_requests_except_allowed?,
          outbound_local_requests_allowlist: Gitlab::CurrentSettings.outbound_local_requests_whitelist # rubocop:disable Naming/InclusiveLanguage -- existing setting
        }
      end

      private

      def allow_local_requests?
        Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
      end
    end
  end
end
