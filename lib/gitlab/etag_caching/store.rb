module Gitlab
  module EtagCaching
    class Store
      EXPIRY_TIME = 20.minutes
      REDIS_NAMESPACE = 'etag:'.freeze

      def get(key)
        Gitlab::Redis.with { |redis| redis.get(redis_key(key)) }
      end

      def touch(key, only_if_missing: false)
        etag = generate_etag

        ::Gitlab::Workhorse.set_key_and_notify(
          redis_key(key), etag,
          expire: EXPIRY_TIME, overwrite: !only_if_missing)

        etag
      end

      private

      def generate_etag
        SecureRandom.hex
      end

      def redis_key(key)
        raise 'Invalid key' unless Gitlab::EtagCaching::Router.match(key)
        
        "#{REDIS_NAMESPACE}#{key}"
      end
    end
  end
end
