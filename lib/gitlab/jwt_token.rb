# frozen_string_literal: true

module Gitlab
  class JWTToken < JSONWebToken::HMACToken
    HMAC_ALGORITHM = 'SHA256'
    HMAC_KEY = 'gitlab-jwt'
    HMAC_EXPIRES_IN = 5.minutes.freeze

    class << self
      def decode(jwt)
        payload = super(jwt, secret).first

        new.tap do |jwt_token|
          jwt_token.id = payload.delete('jti')
          jwt_token.issued_at = payload.delete('iat')
          jwt_token.not_before = payload.delete('nbf')
          jwt_token.expire_time = payload.delete('exp')

          payload.each do |key, value|
            jwt_token[key] = value
          end
        end
      rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::ImmatureSignature => ex
        # we want to log and return on expired and errored tokens
        Gitlab::ErrorTracking.track_exception(ex)
        nil
      end

      def secret
        OpenSSL::HMAC.hexdigest(
          HMAC_ALGORITHM,
          ::Settings.attr_encrypted_db_key_base,
          HMAC_KEY
        )
      end
    end

    def initialize
      super(self.class.secret)
      self.expire_time = self.issued_at + HMAC_EXPIRES_IN.to_i
    end

    def ==(other)
      self.id == other.id &&
        self.payload == other.payload
    end

    def issued_at=(value)
      super(convert_time(value))
    end

    def not_before=(value)
      super(convert_time(value))
    end

    def expire_time=(value)
      super(convert_time(value))
    end

    private

    def convert_time(value)
      # JSONWebToken::Token truncates subsecond precision causing comparisons to
      # fail unless we truncate it here first
      value = value.to_i if value.is_a?(Float)
      value = Time.zone.at(value) if value.is_a?(Integer)
      value
    end
  end
end
