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
        encoded_message, jwt_secret = secret, algorithm: 'HS256', issuer: nil, iat_after: nil, audience: nil,
        jwks: nil)
        options = { algorithm: algorithm }
        options = options.merge(iss: issuer, verify_iss: true) if issuer.present?
        options = options.merge(verify_iat: true) if iat_after.present?
        options = options.merge(aud: audience, verify_aud: true) if audience.present?

        # When a JWKS (key set) is provided, the verification key is selected by
        # the token's `kid` header, which enables key rotation: multiple valid
        # public keys can be trusted at once. The signing key argument must be
        # nil in this case so JWT.decode resolves the key from the set. A secret
        # and a JWKS are mutually exclusive; reject callers that pass both rather
        # than silently dropping the secret.
        if jwks.present?
          raise ArgumentError, 'jwt_secret and jwks are mutually exclusive; pass only one' if jwt_secret.present?

          options = options.merge(jwks: jwks)
          jwt_secret = nil
        end

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

      # Reads a PEM-encoded public key for verifying asymmetrically-signed JWTs
      # (for example ES256/RS256). Unlike #read_secret, this does not enforce the
      # HMAC-specific SECRET_LENGTH because asymmetric keys are not fixed-length
      # shared secrets.
      #
      # OpenSSL::PKey.read silently accepts a private key PEM (verification would
      # still succeed using its public component), so we reject private keys to
      # prevent private key material being loaded into memory through a
      # misconfigured public_key_files path.
      def read_public_key(path)
        OpenSSL::PKey.read(File.read(path)).tap do |key|
          raise "#{path} contains a private key; only public keys are permitted" if key.private?
        end
      end

      # Builds a JWT::JWK::Set from PEM-encoded public key files. Each key is
      # identified by its RFC 7638 thumbprint (`kid`), so the verifier can hold
      # several keys at once and select the matching one from the token's `kid`
      # header. This is the mechanism that allows public keys to be rotated
      # without a hard cutover.
      def public_key_set(paths)
        jwks = Array(paths).map { |path| JWT::JWK.new(read_public_key(path)) }

        JWT::JWK::Set.new(jwks)
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
