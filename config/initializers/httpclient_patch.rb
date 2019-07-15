# frozen_string_literal: true

# By default, httpclient (and hence anything that uses rack-oauth2)
# ignores the system-wide SSL certificate configuration in favor of its
# own cacert.pem. This makes it impossible to use custom certificates
# without patching that file. Until
# https://github.com/nahi/httpclient/pull/386 is merged, we work around
# this limitation by forcing the HTTPClient SSL store to use the default
# system configuration.
module HTTPClient::SSLConfigDefaultPaths
  def initialize(client)
    super

    set_default_paths
  end
end

HTTPClient::SSLConfig.prepend HTTPClient::SSLConfigDefaultPaths
