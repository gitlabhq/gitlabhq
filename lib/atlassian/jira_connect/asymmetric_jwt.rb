# frozen_string_literal: true

module Atlassian
  module JiraConnect
    # See documentation about Atlassian asymmetric JWT verification:
    # https://developer.atlassian.com/cloud/jira/platform/understanding-jwt-for-connect-apps/#verifying-a-asymmetric-jwt-token-for-install-callbacks

    class AsymmetricJwt
      include Gitlab::Utils::StrongMemoize

      KeyFetchError = Class.new(StandardError)

      ALGORITHM = 'RS256'
      PUBLIC_KEY_CDN_URL = 'https://connect-install-keys.atlassian.com/'
      UUID4_REGEX = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/.freeze

      def initialize(token, verification_claims)
        @token = token
        @verification_claims = verification_claims
      end

      def valid?
        claims.present? && claims['qsh'] == verification_qsh
      end

      def iss_claim
        return unless claims

        claims['iss']
      end

      private

      def claims
        strong_memoize(:claims) do
          _, jwt_headers    = decode_token
          public_key        = retrieve_public_key(jwt_headers['kid'])
          decoded_claims, _ = decode_token(public_key, true, **relevant_claims, verify_aud: true, verify_iss: true, algorithm: ALGORITHM)

          decoded_claims
        rescue JWT::DecodeError, OpenSSL::PKey::PKeyError, KeyFetchError
        end
      end

      def decode_token(key = nil, verify = false, **claims)
        Atlassian::Jwt.decode(@token, key, verify, **claims)
      end

      def retrieve_public_key(key_id)
        raise KeyFetchError unless UUID4_REGEX.match?(key_id)

        public_key = Gitlab::HTTP.try_get(PUBLIC_KEY_CDN_URL + key_id).try(:body)

        raise KeyFetchError if public_key.blank?

        OpenSSL::PKey.read(public_key)
      end

      def relevant_claims
        @verification_claims.slice(:aud, :iss)
      end

      def verification_qsh
        @verification_claims[:qsh]
      end
    end
  end
end
