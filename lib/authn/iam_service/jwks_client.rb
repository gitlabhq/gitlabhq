# frozen_string_literal: true

module Authn
  module IamService
    class JwksClient
      include Gitlab::Utils::StrongMemoize

      JwksFetchFailedError = Class.new(StandardError)

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
        response = Gitlab::HTTP.get(endpoint, timeout: 10)

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
        url = Gitlab::Auth::Iam.service_url
        raise Gitlab::Auth::Iam::ConfigurationError, 'IAM service URL is not configured' if url.nil?

        URI.join(url, JWKS_PATH).to_s
      end

      def cache_key
        issuer_hash = Digest::SHA256.hexdigest(Gitlab::Auth::Iam.issuer)[0..8]
        "iam:jwks:#{issuer_hash}"
      end
    end
  end
end
