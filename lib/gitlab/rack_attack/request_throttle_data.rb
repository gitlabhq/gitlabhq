# frozen_string_literal: true

module Gitlab
  module RackAttack
    # Represents throttle information for a request, typically populated from Rack::Attack data.
    #
    # This class encapsulates rate limit state for a specific throttle, including the limit,
    # current observation count, and time window. It provides methods to calculate remaining
    # quota and generate standardized rate limit HTTP headers.
    #
    # @example Creating from Rack::Attack data
    #   data = {
    #     discriminator: '127.0.0.1',
    #     count: 50,
    #     period: 3600,
    #     limit: 100,
    #     epoch_time: Time.now.to_i
    #   }
    #   throttle_data = RequestThrottleData.from_rack_attack('throttle_unauthenticated_api', data)
    #   throttle_data.remaining # => 50
    #   throttle_data.common_response_headers # => { 'RateLimit-Limit' => '100', ... }
    #
    # @see https://github.com/rack/rack-attack Rack::Attack gem
    class RequestThrottleData
      attr_reader :name, :period, :limit, :observed, :now

      # Creates a RequestThrottleData instance from Rack::Attack throttle data
      #
      # @param name [String, Symbol] The name of the throttle (e.g. 'throttle_unauthenticated_api')
      # @param data [Hash] The match data from Rack::Attack containing :count, :epoch_time, :period, and :limit
      # @return [RequestThrottleData, nil] A new instance, or nil if required data is missing
      #
      # @example
      #   data = { count: 50, period: 60, limit: 100, epoch_time: 1609833930 }
      #   RequestThrottleData.from_rack_attack('throttle_api', data)
      def self.from_rack_attack(name, data)
        # Match data example:
        # {:discriminator=>"127.0.0.1", :count=>12, :period=>60 seconds, :limit=>1, :epoch_time=>1609833930}
        # Source: https://github.com/rack/rack-attack/blob/v6.3.0/lib/rack/attack/throttle.rb#L33
        unless name
          Gitlab::AppLogger.warn(
            class: self.name.to_s,
            message: '.from_rack_attack called with nil throttle name'
          )
          return
        end

        required_keys = %i[count epoch_time period limit]
        missing_keys = required_keys.reject { |key| data.key?(key) }

        if missing_keys.any?
          Gitlab::AppLogger.warn(
            class: self.name.to_s,
            message: ".from_rack_attack called with incomplete data for throttle #{name} (#{missing_keys.join(', ')}"
          )
          return
        end

        new(
          name: name.to_s,
          observed: data[:count].to_i,
          now: data[:epoch_time].to_i,
          period: data[:period].to_i,
          limit: data[:limit].to_i
        )
      end

      # Initialize a new RequestThrottleData instance
      #
      # @param name [String] The name of the throttle (e.g. 'throttle_unauthenticated_api')
      # @param period [Integer] The time window in seconds for the throttle
      # @param limit [Integer] The maximum number of requests allowed in the period
      # @param observed [Integer] The current number of requests made in the period
      # @param now [Integer] The current time as a Unix timestamp (epoch time)
      def initialize(name:, period:, limit:, observed:, now:)
        @name = name
        @period = period
        @limit = limit
        @observed = observed
        @now = now
      end

      # Returns common rate limit headers for all requests (both throttled and unthrottled)
      #
      # These headers follow the IETF draft specification for rate limit headers.
      # The limit is normalized (and approximately rounded up) to a 60-second window for
      # compatibility with HAProxy and ecosystem libraries that expect this convention.
      #
      # @return [Hash<String, String>] A hash of HTTP headers with the following keys:
      #   - 'RateLimit-Name': The name of the throttle
      #   - 'RateLimit-Limit': Request quota per 60 seconds (normalized from the actual period). See #rounded_limit.
      #   - 'RateLimit-Observed': Current request count in the time window
      #   - 'RateLimit-Remaining': Remaining requests allowed (Limit - Observed, minimum 0)
      #   - 'RateLimit-Reset': Unix timestamp when the quota resets
      #
      # @see https://github.com/ietf-wg-httpapi/ratelimit-headers/blob/main/draft-ietf-httpapi-ratelimit-headers.md
      #   IETF Rate Limit Headers Draft
      def common_response_headers
        {
          'RateLimit-Name' => name.to_s,
          'RateLimit-Limit' => rounded_limit.to_s,
          'RateLimit-Observed' => observed.to_i.to_s,
          'RateLimit-Remaining' => remaining.to_i.to_s,
          'RateLimit-Reset' => reset_time.to_i.to_s
        }
      end

      # Returns rate limit headers for throttled requests (HTTP 429 responses)
      #
      # Includes all headers from {#common_response_headers} plus additional headers
      # to indicate when the client can retry.
      #
      # @return [Hash<String, String>] A hash containing all common headers plus:
      #   - 'Retry-After': Seconds until quota resets (RFC 7231 standard header)
      #   - 'RateLimit-ResetTime': Reset time in HTTP date format (e.g. 'Tue, 05 Jan 2021 11:00:00 GMT')
      #
      # @see #common_response_headers
      # @see https://www.rfc-editor.org/rfc/rfc7231#page-69 RFC 7231 - Retry-After header
      def throttled_response_headers
        common_response_headers.merge(
          {
            'Retry-After' => retry_after.to_s,
            'RateLimit-ResetTime' => reset_time.httpdate
          }
        )
      end

      # Calculates the request limit normalized to a 60-second window
      #
      # Since HAProxy and many ecosystem libraries expect rate limits expressed as
      # requests per 60 seconds, this method converts the actual limit to that convention.
      #
      # @return [Integer] The limit rounded up to the nearest whole number for a 60-second period
      #
      # @example With a 120-second period
      #   data = RequestThrottleData.new(name: 'test', period: 120, limit: 100, observed: 0, now: Time.now.to_i)
      #   data.rounded_limit # => 50 (100 requests per 120 seconds = 50 per 60 seconds)
      def rounded_limit
        (limit.to_f * 1.minute / period).ceil
      end

      # Calculates the remaining request quota in the current time window
      #
      # @return [Integer] Number of remaining requests, or 0 if the limit has been reached or exceeded
      def remaining
        (limit > observed ? limit - observed : 0)
      end

      # Calculates seconds remaining until the rate limit window resets
      #
      # @return [Integer] Seconds until the quota resets
      def retry_after
        period - (now % period)
      end

      # Calculates the time when the rate limit window will reset
      #
      # @return [Time] The reset time as a Time object
      def reset_time
        Time.at(now + retry_after) # rubocop:disable Rails/TimeZone -- Unix epoch based calculation
      end
    end
  end
end
