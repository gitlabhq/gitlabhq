# frozen_string_literal: true

module Members
  class InviteEmailExperiment < ApplicationExperiment
    exclude { context.actor.created_by.blank? }
    exclude { context.actor.created_by.avatar_url.nil? }

    INVITE_TYPE = 'initial_email'

    def self.initial_invite_email?(invite_type)
      invite_type == INVITE_TYPE
    end

    def resolve_variant_name
      RoundRobin.new(feature_flag_name, %i[activity control]).execute
    end
  end

  class RoundRobin
    CacheError = Class.new(StandardError)

    COUNTER_EXPIRE_TIME = 86400 # one day

    def initialize(key, variants)
      @key = key
      @variants = variants
    end

    def execute
      increment_counter
      resolve_variant_name
    end

    # When the counter would expire
    #
    # @api private Used internally by SRE and debugging purpose
    # @return [Integer] Number in seconds until expiration or false if never
    def counter_expires_in
      Gitlab::Redis::SharedState.with do |redis|
        redis.ttl(key)
      end
    end

    # Return the actual counter value
    #
    # @return [Integer] value
    def counter_value
      Gitlab::Redis::SharedState.with do |redis|
        (redis.get(key) || 0).to_i
      end
    end

    # Reset the counter
    #
    # @private Used internally by SRE and debugging purpose
    # @return [Boolean] whether reset was a success
    def reset!
      redis_cmd do |redis|
        redis.del(key)
      end
    end

    private

    attr_reader :key, :variants

    # Increase the counter
    #
    # @return [Boolean] whether operation was a success
    def increment_counter
      redis_cmd do |redis|
        redis.incr(key)
        redis.expire(key, COUNTER_EXPIRE_TIME)
      end
    end

    def resolve_variant_name
      remainder = counter_value % variants.size

      variants[remainder]
    end

    def redis_cmd
      Gitlab::Redis::SharedState.with { |redis| yield(redis) }

      true
    rescue CacheError => e
      Gitlab::AppLogger.warn("GitLab: An unexpected error occurred in writing to Redis: #{e}")

      false
    end
  end
end
