# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- reuse the existing Atlassian module namespace
module Atlassian
  module Forge
    # Fetches and caches the Atlassian Forge JWKS used to verify FITs. Same
    # Rails.cache + JWT::JWK::Set pattern as Authn::IamService::JwksClient.
    class JwksClient
      JwksFetchFailedError = Class.new(StandardError)
      KeyNotFoundError = Class.new(StandardError)

      JWKS_URL = 'https://forge.cdn.prod.atlassian-dev.net/.well-known/jwks.json'
      MIN_CACHE_TTL = 5.minutes
      MAX_CACHE_TTL = 24.hours
      DEFAULT_CACHE_TTL = 1.hour
      RACE_CONDITION_TTL = 5.seconds
      HTTP_TIMEOUT_SECONDS = 5

      def verification_key_for(kid)
        raise ArgumentError, 'kid cannot be blank' if kid.blank?

        key = extract_verification_key(kid)
        return key if key

        Gitlab::AuthLogger.error(message: 'Forge JWKS key not found', forge_jwks_kid: kid)
        raise KeyNotFoundError, 'Signing key not found in Forge JWKS'
      end

      def keyset
        Rails.cache.fetch(cache_key, race_condition_ttl: RACE_CONDITION_TTL) do |_, options|
          response = fetch_keyset
          options.expires_in = cache_ttl(response)
          parse_keyset(response)
        end
      end

      private

      def fetch_keyset
        response = Gitlab::HTTP.get(JWKS_URL, timeout: HTTP_TIMEOUT_SECONDS)

        raise JwksFetchFailedError, "Failed to fetch Forge JWKS: HTTP #{response.code}" unless response.success?

        response
      rescue *Gitlab::HTTP_V2::HTTP_ERRORS => e
        Gitlab::ErrorTracking.track_exception(e)
        raise JwksFetchFailedError, 'Failed to connect to Forge JWKS endpoint'
      end

      def parse_keyset(response)
        JWT::JWK::Set.new(response.parsed_response)
      rescue JWT::JWKError => e
        Gitlab::ErrorTracking.track_exception(e)
        raise JwksFetchFailedError, 'Failed to parse Forge JWKS: invalid format'
      end

      def extract_verification_key(kid)
        jwk = keyset.find { |key| key[:kid] == kid }

        # verify_key returns the public key for signature verification
        jwk&.verify_key
      end

      def cache_key
        "atlassian:forge:jwks:#{JWKS_URL}"
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
# rubocop:enable Gitlab/BoundedContexts
