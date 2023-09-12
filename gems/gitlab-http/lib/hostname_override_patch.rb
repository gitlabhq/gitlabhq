# frozen_string_literal: true

# This override allows passing `@hostname_override` to the SNI protocol,
# which is used to lookup the correct SSL certificate in the
# request handshake process.
#
# Given we've forced the HTTP request to be sent to the resolved
# IP address in a few scenarios (e.g.: `Gitlab::HTTP_V2` through
# `UrlBlocker.validate!`), we need to provide the _original_
# hostname via SNI in order to have a clean connection setup.
#
# This is ultimately needed in order to avoid DNS rebinding attacks
# through HTTP requests.

require 'net/http'

class OpenSSL::SSL::SSLContext
  attr_accessor :hostname_override
end

class OpenSSL::SSL::SSLSocket
  module HostnameOverride
    # rubocop: disable Gitlab/ModuleWithInstanceVariables
    def hostname=(hostname)
      super(@context.hostname_override || hostname)
    end

    def post_connection_check(hostname)
      super(@context.hostname_override || hostname)
    end
    # rubocop: enable Gitlab/ModuleWithInstanceVariables
  end

  prepend HostnameOverride
end

class Net::HTTP
  attr_accessor :hostname_override

  SSL_IVNAMES << :@hostname_override
  SSL_ATTRIBUTES << :hostname_override

  module HostnameOverride
    def addr_port
      return super unless hostname_override

      addr = hostname_override
      default_port = use_ssl? ? Net::HTTP.https_default_port : Net::HTTP.http_default_port
      default_port == port ? addr : "#{addr}:#{port}"
    end
  end

  prepend HostnameOverride
end
