# frozen_string_literal: true

module Gitlab
  module EtagCaching
    class Store
      InvalidKeyError = Class.new(StandardError)

      EXPIRY_TIME = 20.minutes
      SHARED_STATE_NAMESPACE = 'etag:'

      def get(key)
        with_redis { |redis| redis.get(redis_shared_state_key(key)) }
      end

      def touch(*keys, only_if_missing: false)
        etags = keys.map { generate_etag }

        Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
          with_redis do |redis|
            redis.pipelined do |pipeline|
              keys.each_with_index do |key, i|
                pipeline.set(redis_shared_state_key(key), etags[i], ex: EXPIRY_TIME, nx: only_if_missing)
              end
            end
          end
        end

        keys.size > 1 ? etags : etags.first
      end

      private

      def with_redis(&blk)
        Gitlab::Redis::Cache.with(&blk) # rubocop:disable CodeReuse/ActiveRecord
      end

      def generate_etag
        SecureRandom.hex
      end

      def redis_shared_state_key(key)
        raise InvalidKeyError, "#{key} is invalid" unless valid_key?(key)

        "#{SHARED_STATE_NAMESPACE}#{key}"
      rescue InvalidKeyError => e
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
      end

      def valid_key?(key)
        return true if skip_validation?

        path, header = key.split(':', 2)
        env = {
          'PATH_INFO' => path,
          'HTTP_X_GITLAB_GRAPHQL_RESOURCE_ETAG' => header
        }

        fake_request = ActionDispatch::Request.new(env)
        !!Gitlab::EtagCaching::Router.match(fake_request)
      end

      def skip_validation?
        Rails.env.production?
      end
    end
  end
end
