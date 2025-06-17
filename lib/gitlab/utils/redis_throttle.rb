# frozen_string_literal: true

module Gitlab
  module Utils
    class RedisThrottle
      # Executes a block of code at most once within a given time period using Redis for throttling.
      # This is useful for scheduled tasks that should not execute too frequently.
      #
      # @param [ActiveSupport::Duration, Integer] period: The minimum time period between executions
      # @param [String] cache_key: The key to use for Redis caching (must be unique for each distinct operation)
      # @param [Boolean] skip_in_development: If true, always executes in development environment (default: true)
      # @param [Proc] block: The code to execute if throttling conditions are met
      #
      # @return [Object, false] The result of the block or false if execution was throttled
      #
      # @example Execute a task at most once every hour
      #   Gitlab::Utils::RedisThrottle.execute_every(1.hour, 'my_task:hourly_job') do
      #     puts "This will run once per hour"
      #   end
      #
      def self.execute_every(period, cache_key, skip_in_development: true)
        return yield if skip_in_development && Rails.env.development?
        return yield unless period

        Gitlab::Redis::SharedState.with do |redis|
          key_set = redis.set(cache_key, 1, ex: period, nx: true)
          break false unless key_set

          yield
        end
      end
    end
  end
end
