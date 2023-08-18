# frozen_string_literal: true

module Gitlab
  module JwtAuthenticatable
    # Supposedly the effective key size for HMAC-SHA256 is 256 bits, i.e. 32
    # bytes https://www.rfc-editor.org/rfc/rfc4868#section-2.6
    SECRET_LENGTH = 32

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      include Gitlab::Utils::StrongMemoize

      def decode_jwt(
        encoded_message, jwt_secret = secret, algorithm: 'HS256', issuer: nil, iat_after: nil, audience: nil)
        options = { algorithm: algorithm }
        options = options.merge(iss: issuer, verify_iss: true) if issuer.present?
        options = options.merge(verify_iat: true) if iat_after.present?
        options = options.merge(aud: audience, verify_aud: true) if audience.present?

        decoded_message = JWT.decode(encoded_message, jwt_secret, true, options)
        payload = decoded_message[0]
        if iat_after.present?
          raise JWT::DecodeError, "JWT iat claim is missing" if payload['iat'].blank?

          iat = payload['iat'].to_i
          raise JWT::ExpiredSignature, 'Token has expired' if iat < iat_after.to_i
        end

        decoded_message
      end

      def secret
        strong_memoize(:secret) do
          read_secret(secret_path)
        end
      end

      def read_secret(path)
        Base64.strict_decode64(File.read(path).chomp).tap do |bytes|
          raise "#{path} does not contain #{SECRET_LENGTH} bytes" if bytes.length != SECRET_LENGTH
        end
      end

      def write_secret(path = secret_path)
        bytes = SecureRandom.random_bytes(SECRET_LENGTH)
        File.open(path, 'w:BINARY', 0600) do |f|
          f.chmod(0600) # If the file already existed, the '0600' passed to 'open' above was a no-op.
          f.write(Base64.strict_encode64(bytes))
        end
      end
    end
  end
end
