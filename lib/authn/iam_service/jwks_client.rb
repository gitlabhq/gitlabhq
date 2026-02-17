# frozen_string_literal: true

module Authn
  module IamService
    class JwksClient
      include Gitlab::Utils::StrongMemoize

      JwksFetchFailedError = Class.new(StandardError)
      ConfigurationError = Class.new(StandardError)

      JWKS_PATH = '/.well-known/jwks.json'
      DEFAULT_CACHE_TTL = 1.hour

      def fetch_keys
        Rails.cache.fetch(cache_key) { fetch_and_cache_keys }
      end

      # This is used during JWT verification retry when signature verification fails,
      # which typically indicates the IAM service has rotated its signing keys.
      def refresh_keys
        clear_cache
        fetch_keys
      end

      def clear_cache
        Rails.cache.delete(cache_key)
      end

      private

      def fetch_and_cache_keys
        response = Gitlab::HTTP.get(endpoint, timeout: 5)

        unless response.success?
          raise JwksFetchFailedError,
            "Failed to fetch JWKS from IAM service"
        end

        begin
          keys = JWT::JWK::Set.new(response.parsed_response)
        rescue JWT::JWKError, ArgumentError
          raise JwksFetchFailedError, "Invalid JWKS format: malformed key data"
        end

        # Store with TTL from response
        ttl = parse_cache_ttl(response) || DEFAULT_CACHE_TTL
        Rails.cache.write(cache_key, keys, expires_in: ttl)

        keys
      rescue Errno::ECONNREFUSED, Net::OpenTimeout, Net::ReadTimeout => e
        Gitlab::ErrorTracking.track_exception(e)
        raise JwksFetchFailedError, "Cannot connect to IAM service"
      end

      def parse_cache_ttl(response)
        cache_control = response.headers['cache-control'] || response.headers['Cache-Control']
        return unless cache_control

        match = cache_control.match(/max-age=(\d+)/i)
        match[1].to_i.seconds if match
      end

      def endpoint
        URI.join(service_url, JWKS_PATH).to_s
      end

      def cache_key
        "iam:jwks:#{service_url}"
      end

      def service_url
        url = Gitlab.config.authn.iam_service.url
        raise ConfigurationError, 'IAM service URL is not configured' if url.nil?

        url
      end
    end
  end
end
