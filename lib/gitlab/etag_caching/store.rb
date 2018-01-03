module Gitlab
  module EtagCaching
    class Store
      EXPIRY_TIME = 20.minutes
      SHARED_STATE_NAMESPACE = 'etag:'.freeze

      def get(key)
        Gitlab::Redis::SharedState.with { |redis| redis.get(redis_shared_state_key(key)) }
      end

      def touch(key, only_if_missing: false)
        etag = generate_etag

        Gitlab::Redis::SharedState.with do |redis|
          redis.set(redis_shared_state_key(key), etag, ex: EXPIRY_TIME, nx: only_if_missing)
        end

        etag
      end

      private

      def generate_etag
        SecureRandom.hex
      end

      def redis_shared_state_key(key)
        raise 'Invalid key' if !Rails.env.production? && !Gitlab::EtagCaching::Router.match(key)

        "#{SHARED_STATE_NAMESPACE}#{key}"
      end
    end
  end
end
