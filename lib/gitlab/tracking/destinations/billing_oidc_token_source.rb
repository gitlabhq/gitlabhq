# frozen_string_literal: true

module Gitlab
  module Tracking
    module Destinations
      class BillingOidcTokenSource
        include ::Gitlab::Loggable

        METADATA_BASE_URL = 'http://metadata.google.internal'
        METADATA_FLAVOR_HEADER = 'Metadata-Flavor'
        METADATA_FLAVOR_VALUE = 'Google'
        SERVICE_ACCOUNT_EMAIL_PATH = '/computeMetadata/v1/instance/service-accounts/default/email'
        SERVICE_ACCOUNT_TOKEN_PATH = '/computeMetadata/v1/instance/service-accounts/default/token'
        IAM_CREDENTIALS_BASE_URL = 'https://iamcredentials.googleapis.com/v1'
        HTTP_TIMEOUT = 15
        TOKEN_CACHE_TTL_BUFFER = 60

        def initialize(audience)
          @audience = audience
          @mutex = Mutex.new
        end

        def token
          @mutex.synchronize do
            @cached_token = mint_token unless token_valid?
            @cached_token
          end
        rescue StandardError => e
          Gitlab::ErrorTracking.track_exception(e, audience: @audience)
          Gitlab::AppLogger.error(
            build_structured_payload_labkit(
              message: 'BillingEvents: failed to mint OIDC token',
              audience: @audience,
              Labkit::Fields::ERROR_MESSAGE => e.message
            )
          )
          nil
        end

        private

        def token_valid?
          @cached_token.present? && @expires_at.present? && Time.now.to_i < @expires_at
        end

        def mint_token
          id_token = request_id_token
          return unless id_token

          @expires_at = token_expiry(id_token)
          Gitlab::AppLogger.info(
            build_structured_payload_labkit(
              message: 'BillingEvents: minted OIDC token',
              audience: @audience,
              expires_at: @expires_at
            )
          )
          id_token
        end

        def request_id_token
          uri = "#{IAM_CREDENTIALS_BASE_URL}/projects/-/serviceAccounts/#{service_account_email}:generateIdToken"

          response = Gitlab::HTTP.post(
            uri,
            headers: {
              'Authorization' => "Bearer #{access_token}",
              'Content-Type' => 'application/json; charset=utf-8'
            },
            body: {
              audience: @audience,
              includeEmail: true,
              organizationNumberIncluded: true
            }.to_json,
            open_timeout: HTTP_TIMEOUT,
            read_timeout: HTTP_TIMEOUT
          )

          unless response.success?
            Gitlab::AppLogger.error(
              build_structured_payload_labkit(
                message: 'BillingEvents: generateIdToken request failed',
                audience: @audience,
                Labkit::Fields::HTTP_STATUS_CODE => response.code
              )
            )
            return
          end

          token = Gitlab::Json.safe_parse(response.body)&.dig('token')
          token.presence
        end

        def service_account_email
          response = metadata_get(SERVICE_ACCOUNT_EMAIL_PATH)
          raise "metadata email request failed with #{response.code}" unless response.success?

          response.body.to_s.strip
        end

        def access_token
          response = metadata_get(SERVICE_ACCOUNT_TOKEN_PATH)
          raise "metadata token request failed with #{response.code}" unless response.success?

          Gitlab::Json.safe_parse(response.body)&.dig('access_token')
        end

        def metadata_get(path)
          Gitlab::HTTP.get(
            "#{METADATA_BASE_URL}#{path}",
            headers: { METADATA_FLAVOR_HEADER => METADATA_FLAVOR_VALUE },
            allow_local_requests: true,
            open_timeout: HTTP_TIMEOUT,
            read_timeout: HTTP_TIMEOUT
          )
        end

        def token_expiry(id_token)
          # Signature verification is intentionally skipped (the `false` arg). This token is a
          # credential we present to the collector, which verifies it; we are not the verifier.
          # We decode only to read `exp` for cache TTL. Tampering would require compromising the
          # HTTPS channel to GCP, which would compromise the token itself.
          payload, _header = JWT.decode(id_token, nil, false)
          exp = payload['exp']
          raise "OIDC token is missing 'exp' claim" unless exp

          exp.to_i - TOKEN_CACHE_TTL_BUFFER
        end
      end
    end
  end
end
