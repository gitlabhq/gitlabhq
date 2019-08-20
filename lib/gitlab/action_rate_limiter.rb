# frozen_string_literal: true

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
    # key - An array of ActiveRecord instances or strings
    # threshold_value - The maximum number of times this action should occur in the given time interval. If number is zero is considered disabled.
    def throttled?(key, threshold_value)
      threshold_value > 0 &&
        self.increment(key) > threshold_value
    end

    # Logs request into auth.log
    #
    # request - Web request to be logged
    # type - A symbol key that represents the request.
    # current_user - Current user of the request, it can be nil.
    def log_request(request, type, current_user)
      request_information = {
        message: 'Action_Rate_Limiter_Request',
        env: type,
        remote_ip: request.ip,
        request_method: request.request_method,
        path: request.fullpath
      }

      if current_user
        request_information.merge!({
          user_id: current_user.id,
          username: current_user.username
        })
      end

      Gitlab::AuthLogger.error(request_information)
    end

    private

    def action_key(key)
      serialized = key.map do |obj|
        if obj.is_a?(String)
          "#{obj}"
        else
          "#{obj.class.model_name.to_s.underscore}:#{obj.id}"
        end
      end.join(":")

      "action_rate_limiter:#{action}:#{serialized}"
    end
  end
end
