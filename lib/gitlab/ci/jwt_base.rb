# frozen_string_literal: true

module Gitlab
  module Ci
    class JwtBase < ::JSONWebToken::Token
      NoSigningKeyError = Class.new(StandardError)

      def self.decode(token, key)
        ::JSONWebToken::RSAToken.decode(token, key)
      end

      def encoded
        ::JSONWebToken::RSAToken.encode(payload, key, kid)
      end

      private

      def key
        @key ||= begin
          key_data = Gitlab::CurrentSettings.ci_jwt_signing_key

          raise NoSigningKeyError unless key_data

          OpenSSL::PKey::RSA.new(key_data)
        end
      end

      def kid
        key.public_key.to_jwk[:kid]
      end
    end
  end
end
