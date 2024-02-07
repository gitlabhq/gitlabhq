# frozen_string_literal: true

# This class is part of the Gitlab::HTTP wrapper. It handles local requests and header timeouts
#
# 1. Local requests
#   Depending on the value of the global setting allow_local_requests_from_web_hooks_and_services,
#   this adapter will allow/block connection to internal IPs and/or urls.
#
#   This functionality can be overridden by providing the setting the option
#   allow_local_requests = true in the request. For example:
#   Gitlab::HTTP.get('http://www.gitlab.com', allow_local_requests: true)
#
#   This option will take precedence over the global setting.
#
# 2. Header timeouts
#   When the use_read_total_timeout option is used, that means the receiver
#   of the HTTP request cannot be trusted. Gitlab::HTTP_V2::BufferedIo will be used,
#   to read header data. It is a modified version of Net::BufferedIO that
#   raises a timeout error if reading header data takes too much time.

require 'httparty'
require_relative 'net_http_adapter'
require_relative 'url_blocker'

module Gitlab
  module HTTP_V2
    class NewConnectionAdapter < HTTParty::ConnectionAdapter
      def initialize(...)
        super

        @allow_local_requests = options.delete(:allow_local_requests)
        @extra_allowed_uris = options.delete(:extra_allowed_uris)
        @deny_all_requests_except_allowed = options.delete(:deny_all_requests_except_allowed)
        @outbound_local_requests_allowlist = options.delete(:outbound_local_requests_allowlist)
        @dns_rebinding_protection_enabled = options.delete(:dns_rebinding_protection_enabled)
      end

      def connection
        result = validate_url_with_proxy!(uri)
        @uri = result.uri
        hostname = result.hostname

        http = super
        http.hostname_override = hostname if hostname

        unless result.use_proxy
          http.proxy_from_env = false
          http.proxy_address = nil
        end

        net_adapter = NetHttpAdapter.new(http.address, http.port)

        http.instance_variables.each do |variable|
          net_adapter.instance_variable_set(variable, http.instance_variable_get(variable))
        end

        net_adapter
      end

      private

      def validate_url_with_proxy!(url)
        UrlBlocker.validate_url_with_proxy!(url, **url_blocker_options)
      rescue UrlBlocker::BlockedUrlError => e
        raise BlockedUrlError, "URL is blocked: #{e.message}"
      end

      def url_blocker_options
        {
          allow_local_network: @allow_local_requests,
          allow_localhost: @allow_local_requests,
          extra_allowed_uris: @extra_allowed_uris,
          schemes: %w[http https],
          deny_all_requests_except_allowed: @deny_all_requests_except_allowed,
          outbound_local_requests_allowlist: @outbound_local_requests_allowlist,
          dns_rebind_protection: @dns_rebinding_protection_enabled
        }.compact
      end
    end
  end
end
