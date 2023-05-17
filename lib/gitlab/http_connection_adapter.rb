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
#   of the HTTP request cannot be trusted. Gitlab::BufferedIo will be used,
#   to read header data. It is a modified version of Net::BufferedIO that
#   raises a timeout error if reading header data takes too much time.

module Gitlab
  class HTTPConnectionAdapter < HTTParty::ConnectionAdapter
    extend ::Gitlab::Utils::Override

    override :connection
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

      gitlab_http = Gitlab::NetHttpAdapter.new(http.address, http.port)

      http.instance_variables.each do |variable|
        gitlab_http.instance_variable_set(variable, http.instance_variable_get(variable))
      end

      gitlab_http
    end

    private

    def validate_url_with_proxy!(url)
      Gitlab::UrlBlocker.validate_url_with_proxy!(
        url, allow_local_network: allow_local_requests?,
        allow_localhost: allow_local_requests?,
        allow_object_storage: allow_object_storage?,
        dns_rebind_protection: dns_rebind_protection?,
        schemes: %w[http https])
    rescue Gitlab::UrlBlocker::BlockedUrlError => e
      raise Gitlab::HTTP::BlockedUrlError, "URL is blocked: #{e.message}"
    end

    def allow_local_requests?
      options.fetch(:allow_local_requests, allow_settings_local_requests?)
    end

    def allow_object_storage?
      options.fetch(:allow_object_storage, false)
    end

    def dns_rebind_protection?
      Gitlab::CurrentSettings.dns_rebinding_protection_enabled?
    end

    def allow_settings_local_requests?
      Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
    end
  end
end
