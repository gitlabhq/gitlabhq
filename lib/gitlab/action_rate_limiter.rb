module Gitlab
  # This class implements a simple rate limiter that can be used to throttle
  # certain actions. Unlike Rack Attack and Rack::Throttle, which operate at
  # the middleware level, this can be used at the controller level.
  class ActionRateLimiter
    TIME_TO_EXPIRE = 60 # 1 min

    attr_accessor :action, :expiry_time

    def initialize(action:, expiry_time: TIME_TO_EXPIRE)
      @action = action
      @expiry_time = expiry_time
    end

    # Increments the given cache key and increments the value by 1 with the
    # given expiration time. Returns the incremented value.
    #
    # key - An array of ActiveRecord instances
    def increment(key)
      value = 0

      Gitlab::Redis::Cache.with do |redis|
        cache_key = action_key(key)
        value = redis.incr(cache_key)
        redis.expire(cache_key, expiry_time) if value == 1
      end

      value
    end

    # Increments the given key and returns true if the action should
    # be throttled.
    #
    # key - An array of ActiveRecord instances
    # threshold_value - The maximum number of times this action should occur in the given time interval
    def throttled?(key, threshold_value)
      self.increment(key) > threshold_value
    end

    private

    def action_key(key)
      serialized = key.map { |obj| "#{obj.class.model_name.to_s.underscore}:#{obj.id}" }.join(":")
      "action_rate_limiter:#{action}:#{serialized}"
    end
  end
end
