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

    def increment(key)
      value = 0

      Gitlab::Redis::Cache.with do |redis|
        cache_key = "action_rate_limiter:#{action.to_s}:#{key}"
        value = redis.incr(cache_key)
        redis.expire(cache_key, expiry_time) if value == 1
      end

      value
    end

    def throttled?(key, threshold_value)
      self.increment(key) > threshold_value
    end
  end
end
