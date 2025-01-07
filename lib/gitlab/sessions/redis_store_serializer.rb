# frozen_string_literal: true

module Gitlab
  module Sessions
    module RedisStoreSerializer
      def self.load(val)
        deserialized = Marshal.load(val) # rubocop:disable Security/MarshalLoad -- We're loading session data similar to Redis::Store::Serialization#get from redis-store gem

        return deserialized if deserialized.is_a?(Hash)

        # Session data can be an instance of ActiveSupport::Cache::Entry
        # when we're using session store based on ActionDispatch::Session::CacheStore
        # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176108
        deserialized&.value
      rescue StandardError => e
        Gitlab::ErrorTracking.track_and_raise_exception(e)
      end

      def self.dump(val)
        Marshal.dump(val)
      end
    end
  end
end
