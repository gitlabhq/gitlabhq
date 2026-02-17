# frozen_string_literal: true

module Authn
  module IamService
    class JwksClient
      JwksFetchFailedError = Class.new(StandardError)
      ConfigurationError = Class.new(StandardError)
      KeyNotFoundError = Class.new(StandardError)

      JWKS_PATH = '/.well-known/jwks.json'
      RACE_CONDITION_TTL = 5.seconds
      HTTP_TIMEOUT_SECONDS = 5

      def verification_key_for(kid)
        raise ArgumentError, "kid cannot be blank" if kid.blank?

        key = extract_verification_key(kid)
        return key if key

        Gitlab::AuthLogger.error(
          message: 'JWKS key not found',
          iam_jwks_kid: kid,
          iam_jwks_service_url: service_url
        )
        raise KeyNotFoundError, "Signing key not found in JWKS"
      end

      # Backward compatibility methods - to be removed in follow-up MR
      # These methods maintain the old API while JwtValidationService transitions
      # to using verification_key_for

      def fetch_keys
        keyset
      end

      def refresh_keys
        keyset(force: true)
      end

      private

      def keyset(force: false)
        Rails.cache.fetch(cache_key, expires_in: cache_ttl, race_condition_ttl: RACE_CONDITION_TTL,
          force: force
        ) { fetch_keyset }
      end

      def fetch_keyset
        response = Gitlab::HTTP.get(endpoint, timeout: HTTP_TIMEOUT_SECONDS)

        unless response.success?
          raise JwksFetchFailedError, "Failed to fetch keyset from IAM service: HTTP #{response.code}"
        end

        parse_keyset(response)
      rescue JWT::JWKError => e
        Gitlab::ErrorTracking.track_exception(e)
        raise JwksFetchFailedError, "Failed to parse keyset: invalid JWKS format"
      rescue *Gitlab::HTTP_V2::HTTP_ERRORS => e
        Gitlab::ErrorTracking.track_exception(e)
        raise JwksFetchFailedError, "Failed to connect to IAM service"
      end

      def parse_keyset(response)
        parsed_keyset = JWT::JWK::Set.new(response.parsed_response)

        kids = parsed_keyset.map(&:kid)
        Gitlab::AuthLogger.debug(
          message: 'JWKS fetched successfully',
          iam_jwks_kids: kids,
          iam_jwks_kid_count: kids.size,
          iam_jwks_service_url: service_url
        )

        parsed_keyset
      end

      def extract_verification_key(kid)
        jwk = keyset.find { |key| key[:kid] == kid }

        # verify_key returns the public key (OpenSSL::PKey::RSA) for signature verification
        jwk&.verify_key
      end

      def endpoint
        URI.join(service_url, JWKS_PATH).to_s
      rescue URI::InvalidURIError => e
        raise ConfigurationError, "Invalid IAM service URL: #{e.message}"
      end

      def cache_key
        "iam:jwks:#{service_url}"
      end

      def cache_ttl
        ttl = Gitlab.config.authn.iam_service.jwks_cache_ttl
        raise ConfigurationError, 'JWKS cache TTL must be a positive number' unless ttl.is_a?(Numeric) && ttl > 0

        ttl
      end

      def service_url
        url = Gitlab.config.authn.iam_service.url
        raise ConfigurationError, 'IAM service URL is not configured' if url.nil?

        url
      end
    end
  end
end
