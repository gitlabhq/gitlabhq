# frozen_string_literal: true

module Atlassian
  module JiraConnect
    module Jwt
      # See documentation about Atlassian asymmetric JWT verification:
      # https://developer.atlassian.com/cloud/jira/platform/understanding-jwt-for-connect-apps/#verifying-a-asymmetric-jwt-token-for-install-callbacks

      class Asymmetric
        include Gitlab::Utils::StrongMemoize

        KeyFetchError = Class.new(StandardError)

        ALGORITHM = 'RS256'
        DEFAULT_PUBLIC_KEY_CDN_URL = 'https://connect-install-keys.atlassian.com'
        PROXY_PUBLIC_KEY_PATH = '/-/jira_connect/public_keys'
        KEY_ID_REGEX = %r{\A[A-Za-z0-9_\-\/]+\z}

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

            decoded_claims(public_key)
          rescue JWT::DecodeError, OpenSSL::PKey::PKeyError, KeyFetchError => e
            Gitlab::ErrorTracking.track_exception(e)
            nil
          end
        end

        def decoded_claims(public_key)
          decode_token(
            public_key,
            true,
            **relevant_claims,
            verify_aud: true,
            verify_iss: true,
            algorithm: ALGORITHM
          ).first
        end

        def decode_token(key = nil, verify = false, **claims)
          Atlassian::Jwt.decode(@token, key, verify, **claims)
        end

        def retrieve_public_key(key_id)
          raise KeyFetchError unless KEY_ID_REGEX.match?(key_id)

          public_key = Gitlab::HTTP.try_get("#{public_key_cdn_url}/#{key_id}").try(:body)

          raise KeyFetchError if public_key.blank?

          OpenSSL::PKey.read(public_key)
        end

        def relevant_claims
          @verification_claims.slice(:aud, :iss)
        end

        def verification_qsh
          @verification_claims[:qsh]
        end

        def public_key_cdn_url
          public_key_cdn_url_setting.presence || DEFAULT_PUBLIC_KEY_CDN_URL
        end

        def public_key_cdn_url_setting
          @public_key_cdn_url_setting ||=
            if Gitlab::CurrentSettings.jira_connect_proxy_url.present?
              Gitlab::Utils.append_path(Gitlab::CurrentSettings.jira_connect_proxy_url, PROXY_PUBLIC_KEY_PATH)
            end
        end
      end
    end
  end
end
