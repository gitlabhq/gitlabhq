# frozen_string_literal: true

module RestClient
  class Request
    attr_accessor :hostname_override

    module UrlBlocker
      def transmit(uri, req, payload, &block)
        begin
          ip, hostname_override = Gitlab::HTTP_V2::UrlBlocker.validate!(
            uri,
            allow_local_network: allow_settings_local_requests?,
            allow_localhost: allow_settings_local_requests?,
            dns_rebind_protection: dns_rebind_protection?,
            deny_all_requests_except_allowed: Gitlab::CurrentSettings.deny_all_requests_except_allowed?,
            schemes: %w[http https],
            outbound_local_requests_allowlist: Gitlab::CurrentSettings.outbound_local_requests_whitelist) # rubocop:disable Naming/InclusiveLanguage -- existing setting

          self.hostname_override = hostname_override
        rescue Gitlab::HTTP_V2::UrlBlocker::BlockedUrlError => e
          raise ArgumentError, "URL is blocked: #{e.message}"
        end

        # Gitlab::HTTP_V2::UrlBlocker returns a Addressable::URI which we need to coerce
        # to URI so that rest-client can use it to determine if it's a
        # URI::HTTPS or not. It uses it to set `net.use_ssl` to true or not:
        #
        # https://github.com/rest-client/rest-client/blob/f450a0f086f1cd1049abbef2a2c66166a1a9ba71/lib/restclient/request.rb#L656
        ip_as_uri = URI.parse(ip)
        super(ip_as_uri, req, payload, &block)
      end

      def net_http_object(hostname, port)
        super.tap do |http|
          http.hostname_override = hostname_override if hostname_override
        end
      end

      private

      def dns_rebind_protection?
        return false if Gitlab.http_proxy_env?

        Gitlab::CurrentSettings.dns_rebinding_protection_enabled?
      end

      def allow_settings_local_requests?
        Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
      end
    end

    prepend UrlBlocker
  end
end
