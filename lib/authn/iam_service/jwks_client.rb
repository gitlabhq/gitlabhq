# frozen_string_literal: true

module Authn
  module IamService
    class JwksClient
      JwksFetchFailedError = Class.new(StandardError)
      ConfigurationError = Class.new(StandardError)
      KeyNotFoundError = Class.new(StandardError)

      JWKS_PATH = '/.well-known/jwks.json'
      MIN_CACHE_TTL = 5.minutes
      MAX_CACHE_TTL = 24.hours
      DEFAULT_CACHE_TTL = 1.hour
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

      def keyset
        Rails.cache.fetch(cache_key, race_condition_ttl: RACE_CONDITION_TTL) do |_, options|
          response = fetch_keyset
          options.expires_in = cache_ttl(response)
          parse_keyset(response)
        end
      end

      private

      def service_url
        Authn::IamAuthService.url
      rescue Authn::IamAuthService::ConfigurationError => e
        raise ConfigurationError, e.message
      end

      def fetch_keyset
        response = Gitlab::HTTP.get(endpoint, timeout: HTTP_TIMEOUT_SECONDS)

        unless response.success?
          raise JwksFetchFailedError, "Failed to fetch keyset from IAM service: HTTP #{response.code}"
        end

        response
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
      rescue JWT::JWKError => e
        Gitlab::ErrorTracking.track_exception(e)
        raise JwksFetchFailedError, "Failed to parse keyset: invalid JWKS format"
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

      def cache_ttl(response)
        cache_control_header = response.headers['cache-control'] || response.headers['Cache-Control']
        return DEFAULT_CACHE_TTL unless cache_control_header

        match = cache_control_header.match(/max-age=(\d+)/i)
        ttl = match.present? ? match[1].to_i.seconds : 0

        ttl >= MIN_CACHE_TTL && ttl <= MAX_CACHE_TTL ? ttl : DEFAULT_CACHE_TTL
      end
    end
  end
end
