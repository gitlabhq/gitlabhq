# frozen_string_literal: true

# Demonstrated Proof of Possession (DPoP) is a mechanism to tie a user's
# Personal Access Token (PAT) to one of their signing keys.
#
# A DPoP Token is a signed JSON Web Token. This class implements
# the logic to ensure a provided DPoP Token is well-formed, cryptographically
# signed and belongs to the provided user.
#
module Gitlab
  module Auth
    class DpopTokenUser
      SUPPORTED_JWS_ALGORITHMS = { 'ssh-rsa' => 'RS512' }.freeze
      SUPPORTED_TYPES = ['dpop+jwt'].freeze
      SUPPORTED_KEY_TYPES = ['RSA'].freeze
      SUPPORTED_PROOF_KEY_ID_HASHING_ALGORITHMS = ['SHA256'].freeze

      def initialize(token:, user:, personal_access_token_plaintext:)
        @token = token
        @user = user
        @personal_access_token_plaintext = personal_access_token_plaintext
      end

      def validate!
        token.validate!
        pat_belongs_to_user!
        valid_token_for_user!
        valid_access_token_hash!
      end

      private

      attr_reader :token, :user, :personal_access_token_plaintext

      def pat_belongs_to_user!
        return if user.personal_access_tokens.active.find_by_token(personal_access_token_plaintext).present?

        raise Gitlab::Auth::DpopValidationError, 'Personal access token does not belong to the requesting user'
      end

      # Check that the DPoP is signed with a SSH key belonging to the user
      def valid_token_for_user!
        user_public_key = signing_key_for_user!
        openssh_public_key = convert_public_key_to_openssh_key!(user_public_key)

        payload, header = decode_json_token!(user_public_key, openssh_public_key)
        raise Gitlab::Auth::DpopValidationError, 'Unable to decode JWT' if payload.nil? || header.nil?

        jwk = header['jwk']

        begin
          unless openssh_public_key.to_s == OpenSSL::PKey.read(JWT::JWK::RSA.import(jwk).public_key.to_pem).to_s
            raise 'Failed to parse JWK: invalid JWK'
          end
        rescue StandardError => e
          raise Gitlab::Auth::DpopValidationError, e
        end
      end

      def decode_json_token!(user_public_key, openssh_public_key)
        # Decode the JSON token again, this time with the key,
        # the expected algorithm, verifying all the timestamps, etc
        # Overwrites the attrs, in case .decode returns a different result
        # when verify is true.
        algorithm = algorithm_for_dpop_validation(user_public_key)

        JWT.decode(
          token.data,
          openssh_public_key,
          true,
          {
            required_claims: %w[exp ath iat],
            algorithm: algorithm,
            verify_iat: true
          }
        )
      rescue JWT::DecodeError => e
        raise Gitlab::Auth::DpopValidationError, "Malformed JWT, unable to decode. #{e.message}"
      end

      def signing_key_for_user!
        # Gets a signing key from the user based on the fingerprint.
        fingerprint = token.header['kid']&.delete_prefix('SHA256:')

        key = user.keys.signing.find_by_fingerprint_sha256(fingerprint)&.key
        raise Gitlab::Auth::DpopValidationError, "No matching key found" unless key

        # Validate the signing key uses a supported algorithm.
        algorithm = key.split(' ').first

        return key if algorithm.casecmp?('ssh-rsa')

        raise Gitlab::Auth::DpopValidationError, 'Currently only RSA keys are supported'
      end

      # Finds the algorithm from the public key to decode the JWT in
      # valid_for_user!
      def algorithm_for_dpop_validation(key)
        SUPPORTED_JWS_ALGORITHMS.each do |key_algorithm, jwt_algorithm|
          return jwt_algorithm if key.start_with?(key_algorithm)
        end
        nil
      end

      def convert_public_key_to_openssh_key!(key)
        SSHData::PublicKey.parse_openssh(key).openssl
      rescue SSHData::DecodeError => e
        raise Gitlab::Auth::DpopValidationError, "Unable to parse public key. #{e.message}"
      end

      # Check that the DPoP contains a hash of the PAT being used.
      # Users can have multiple PATs, so we still need to check that
      # they created this DPoP for this particular PAT.
      def valid_access_token_hash!
        expected_hash = Base64.urlsafe_encode64(
          Digest::SHA256.digest(personal_access_token_plaintext),
          padding: false
        )

        return if ActiveSupport::SecurityUtils.secure_compare(token.payload['ath'], expected_hash)

        raise Gitlab::Auth::DpopValidationError, 'Incorrect access token hash in JWT'
      end
    end
  end
end
