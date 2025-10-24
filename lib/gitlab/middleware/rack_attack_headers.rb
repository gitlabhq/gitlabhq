# frozen_string_literal: true

module Gitlab
  module Middleware
    # Rack middleware that adds rate limit headers to all responses processed by Rack::Attack.
    #
    # Unlike the default Rack::Attack behavior (which only adds headers to throttled requests),
    # this middleware adds rate limit headers to ALL requests that have throttle data available
    # and are not already rate-limited (i.e. HTTP status 429).
    # This enables clients to proactively adjust their request rates before hitting limits,
    # improving the overall user experience and reducing unnecessary 429 errors.
    #
    # The middleware is controlled by the `rate_limiting_headers_for_unthrottled_requests`
    # feature flag and integrates with {Gitlab::RackAttack::RequestThrottleData} to generate
    # standardized rate limit headers.
    #
    # @example Typical request flow
    #   # Request comes in -> Rack::Attack processes it -> This middleware adds headers
    #   # Response: 200 OK
    #   # Headers: RateLimit-Limit: 100, RateLimit-Remaining: 75, RateLimit-Reset: 1234567890, etc.
    #
    # When multiple throttles apply to a request, the most restrictive one (lowest remaining
    # quota) is used for the headers.
    #
    # @see Gitlab::RackAttack::RequestThrottleData
    # @see https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/25372
    class RackAttackHeaders
      # Rack environment key where Rack::Attack stores throttle data
      RACK_ATTACK_THROTTLE_DATA_KEY = 'rack.attack.throttle_data'

      # Initialize the middleware
      #
      # @param app [#call] The Rack application
      def initialize(app)
        @app = app
      end

      # Process the request and add rate limit headers if applicable
      #
      # @param env [Hash] The Rack environment
      # @return [Array<Integer, Hash, Object>] Standard Rack response tuple (status, headers, body)
      def call(env)
        status, headers, body = @app.call(env)

        return [status, headers, body] unless feature_enabled?

        # Add rate limit headers if Rack::Attack has throttle data
        if should_add_headers?(env, status)
          rate_limit_headers = generate_headers(env)
          headers.merge!(rate_limit_headers) if rate_limit_headers.present?
        end

        [status, headers, body]
      end

      private

      def feature_enabled?
        Feature.enabled?(
          :rate_limiting_headers_for_unthrottled_requests,
          Feature.current_request
        )
      end

      # Determine whether rate limit headers should be added to this response
      #
      # Headers are NOT added if:
      # - The response is already a 429 (throttled by Rack::Attack, headers already added)
      # - No throttle data is available in the environment
      #
      # @param env [Hash] The Rack environment
      # @param status [Integer] The HTTP response status code
      # @return [Boolean] true if headers should be added
      def should_add_headers?(env, status)
        # Skip if already throttled (headers already added by throttled_responder)
        return false if status == 429

        # Skip if no throttle data available
        return false unless env[RACK_ATTACK_THROTTLE_DATA_KEY].present?

        true
      end

      # Generate rate limit headers from Rack::Attack throttle data
      #
      # When multiple throttles are active for a request, selects the most restrictive one
      # (the one with the lowest remaining quota) to use for the headers.
      #
      # @param env [Hash] The Rack environment containing throttle data
      # @return [Hash<String, String>, nil] Rate limit headers, or nil if data is invalid
      def generate_headers(env)
        active_throttles = env[RACK_ATTACK_THROTTLE_DATA_KEY]

        return unless active_throttles.is_a?(Hash) && active_throttles.present?

        # Rack::Attack throttle data structure:
        # { 'throttle_name' => { discriminator:, count:, period:, limit:, epoch_time: } }
        # @see https://github.com/rack/rack-attack/blob/427fdfabbc4b6283af14b6916dec4d2d4074e9e4/lib/rack/attack/throttle.rb#L41
        name, data = find_most_restrictive_throttle(active_throttles)

        throttle_data = Gitlab::RackAttack::RequestThrottleData.from_rack_attack(name, data)

        return unless throttle_data

        throttle_data.common_response_headers
      end

      # Find the most restrictive throttle from a set of active throttles
      #
      # The most restrictive throttle is defined as the one with the lowest remaining
      # request quota (limit - count). This ensures clients see the most conservative
      # rate limit information when multiple throttles apply.
      #
      # @param throttles [Hash] Hash of throttle data from Rack::Attack
      #   Structure: { 'throttle_name' => { discriminator:, count:, period:, limit:, epoch_time: } }
      # @return [Array<String, Hash>] A tuple of [throttle_name, throttle_data]
      #
      # @example
      #   throttles = {
      #     'throttle_api' => { count: 50, limit: 100 },  # 50 remaining
      #     'throttle_web' => { count: 95, limit: 100 }   # 5 remaining (most restrictive)
      #   }
      #   find_most_restrictive_throttle(throttles)
      #   # => ['throttle_web', { count: 95, limit: 100 }]
      def find_most_restrictive_throttle(throttles)
        # Select the throttle with the lowest remaining quota (limit - count)
        throttles.min_by do |_, data|
          limit = data[:limit] || 0
          count = data[:count] || 0
          limit - count
        end
      end
    end
  end
end
