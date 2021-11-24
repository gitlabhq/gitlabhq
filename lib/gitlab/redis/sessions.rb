# frozen_string_literal: true

module Gitlab
  module Redis
    class Sessions < ::Gitlab::Redis::Wrapper
      SESSION_NAMESPACE = 'session:gitlab'
      USER_SESSIONS_NAMESPACE = 'session:user:gitlab'
      USER_SESSIONS_LOOKUP_NAMESPACE = 'session:lookup:user:gitlab'
      IP_SESSIONS_LOOKUP_NAMESPACE = 'session:lookup:ip:gitlab2'
      OTP_SESSIONS_NAMESPACE = 'session:otp'

      class << self
        # The data we store on Sessions used to be stored on SharedState.
        def config_fallback
          SharedState
        end

        private

        def redis
          # Don't use multistore if redis.sessions configuration is not provided
          return super if config_fallback?

          primary_store = ::Redis.new(params)
          secondary_store = ::Redis.new(config_fallback.params)

          MultiStore.new(primary_store, secondary_store, name)
        end
      end

      def store(extras = {})
        # Don't use multistore if redis.sessions configuration is not provided
        return super if self.class.config_fallback?

        primary_store = create_redis_store(redis_store_options, extras)
        secondary_store = create_redis_store(self.class.config_fallback.params, extras)

        MultiStore.new(primary_store, secondary_store, self.class.name)
      end

      private

      def create_redis_store(options, extras)
        ::Redis::Store.new(options.merge(extras))
      end
    end
  end
end
