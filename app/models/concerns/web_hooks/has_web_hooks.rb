# frozen_string_literal: true

module WebHooks
  module HasWebHooks
    WEB_HOOK_CACHE_EXPIRY = 1.hour

    def any_hook_failed?
      hooks.disabled.exists?
    end

    def web_hook_failure_redis_key
      "any_web_hook_failed:#{id}"
    end

    def last_failure_redis_key
      "web_hooks:last_failure:#{self.class.name.underscore}-#{id}"
    end

    def get_web_hook_failure
      Gitlab::Redis::SharedState.with do |redis|
        current = redis.get(web_hook_failure_redis_key)

        Gitlab::Utils.to_boolean(current) if current
      end
    end

    def fetch_web_hook_failure
      Gitlab::Redis::SharedState.with do |_redis|
        current = get_web_hook_failure
        next current unless current.nil?

        cache_web_hook_failure
      end
    end

    def cache_web_hook_failure(state = any_hook_failed?)
      Gitlab::Redis::SharedState.with do |redis|
        redis.set(web_hook_failure_redis_key, state.to_s, ex: WEB_HOOK_CACHE_EXPIRY)

        state
      end
    end

    def last_webhook_failure
      last_failure = Gitlab::Redis::SharedState.with do |redis|
        redis.get(last_failure_redis_key)
      end

      DateTime.parse(last_failure) if last_failure
    end
  end
end
