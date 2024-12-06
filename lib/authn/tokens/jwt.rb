# frozen_string_literal: true

# This class provides methods to encode and decode JWTs using RSA encryption.
# It is designed to work within the GitLab authentication system, providing
# secure token generation and verification for various subjects.
#
# Key features:
# - RSA-based encoding and decoding of JWTs
# - Validation of JWT format and structure
# - Configurable subject types and global ID parsing
# - Support for custom token prefixes
#
# Usage:
# - Use `rsa_encode` to create new JWTs with any subjects
# - Use `rsa_decode` to verify and extract information from existing JWTs
#
module Authn
  module Tokens
    class Jwt
      include Gitlab::Utils::StrongMemoize

      InvalidSubjectForTokenError = Class.new(StandardError)

      ISSUER = Settings.gitlab.host
      AUDIENCE = 'gitlab-authz-token'
      VERSION = '0.1.0'

      class << self
        def rsa_encode(subject:, signing_key:, expire_time:, token_prefix:, custom_payload: {})
          subject_global_id = GlobalID.create(subject).to_s if subject
          raise InvalidSubjectForTokenError unless subject_global_id.present?

          jwt = ::JSONWebToken::Token.new.tap do |token|
            token.subject = subject_global_id
            token.issuer = ISSUER
            token.audience = AUDIENCE
            token.expire_time = expire_time
            token[:version] = VERSION

            custom_payload.each { |key, value| token[key] = value } if custom_payload.present?
          end

          token = ::JSONWebToken::RSAToken.encode(
            jwt.payload,
            signing_key,
            signing_key.public_key.to_jwk[:kid]
          )

          token_prefix + token
        end

        def rsa_decode(token:, signing_public_key:, subject_type:, token_prefix:)
          return unless token.start_with?(token_prefix)

          token = token.delete_prefix(token_prefix)

          payload, _header = ::JSONWebToken::RSAToken.decode(token, signing_public_key)

          new(payload: payload, subject_type: subject_type)
        rescue JWT::DecodeError
          # The token received is not a JWT
          nil
        end
      end

      def initialize(payload:, subject_type:)
        @payload = payload
        @subject_type = subject_type
      end

      def subject
        return unless payload

        GitlabSchema.parse_gid(payload['sub'], expected_type: subject_type)&.find
      rescue Gitlab::Graphql::Errors::ArgumentError
        # The subject doesn't exist anymore
        nil
      end
      strong_memoize_attr :subject

      attr_reader :payload, :subject_type
    end
  end
end
