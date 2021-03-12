# frozen_string_literal: true

module Gitlab
  module EtagCaching
    class Store
      InvalidKeyError = Class.new(StandardError)

      EXPIRY_TIME = 20.minutes
      SHARED_STATE_NAMESPACE = 'etag:'

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
