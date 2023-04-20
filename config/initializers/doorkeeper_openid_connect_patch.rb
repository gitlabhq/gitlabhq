# frozen_string_literal: true

# This pulls in
# https://github.com/doorkeeper-gem/doorkeeper-openid_connect/pull/194
# to ensure generated `kid` values are RFC 7638-compliant.
require 'doorkeeper/openid_connect'

raise 'This patch is only needed for doorkeeper_openid_connect v1.8.5' if Doorkeeper::OpenidConnect::VERSION != '1.8.5'

module Doorkeeper
  module OpenidConnect
    def self.signing_key
      key =
        if %i[HS256 HS384 HS512].include?(signing_algorithm)
          configuration.signing_key
        else
          OpenSSL::PKey.read(configuration.signing_key)
        end

      ::JWT::JWK.new(key, { kid_generator: JWT::JWK::Thumbprint })
    end
  end
end
