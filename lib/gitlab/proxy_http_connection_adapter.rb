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
      if !allow_local_requests? && blocked_url?
        raise URI::InvalidURIError
      end

      super
    end

    private

    def blocked_url?
      Gitlab::UrlBlocker.blocked_url?(uri, allow_private_networks: false)
    end

    def allow_local_requests?
      options.fetch(:allow_local_requests, allow_settings_local_requests?)
    end

    def allow_settings_local_requests?
      Gitlab::CurrentSettings.allow_local_requests_from_hooks_and_services?
    end
  end
end
