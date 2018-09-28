# This class is part of the Gitlab::HTTP wrapper. Depending on the value
# of the global setting allow_local_requests_from_hooks_and_services this adapter
# will allow/block connection to internal IPs and/or urls.
#
# This functionality can be overriden by providing the setting the option
# allow_local_requests = true in the request. For example:
# Gitlab::HTTP.get('http://www.gitlab.com', allow_local_requests: true)
#
# This option will take precedence over the global setting.
module Gitlab
  class ProxyHTTPConnectionAdapter < HTTParty::ConnectionAdapter
    def connection
      unless allow_local_requests?
        begin
          Gitlab::UrlBlocker.validate!(uri, allow_local_network: false)
        rescue Gitlab::UrlBlocker::BlockedUrlError => e
          raise Gitlab::HTTP::BlockedUrlError, "URL '#{uri}' is blocked: #{e.message}"
        end
      end

      super
    end

    private

    def allow_local_requests?
      options.fetch(:allow_local_requests, allow_settings_local_requests?)
    end

    def allow_settings_local_requests?
      Gitlab::CurrentSettings.allow_local_requests_from_hooks_and_services?
    end
  end
end
