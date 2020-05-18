# frozen_string_literal: true

module Ci
  class InstanceVariable < ApplicationRecord
    extend Gitlab::Ci::Model
    include Ci::NewHasVariable
    include Ci::Maskable

    alias_attribute :secret_value, :value

    validates :key, uniqueness: {
      message: "(%{value}) has already been taken"
    }

    scope :unprotected, -> { where(protected: false) }
    after_commit { self.class.touch_redis_cache_timestamp }

    class << self
      def all_cached
        cached_data[:all]
      end

      def unprotected_cached
        cached_data[:unprotected]
      end

      def touch_redis_cache_timestamp(time = Time.current.to_f)
        shared_backend.write(:ci_instance_variable_changed_at, time)
      end

      private

      def cached_data
        fetch_memory_cache(:ci_instance_variable_data) do
          all_records = unscoped.all.to_a

          { all: all_records, unprotected: all_records.reject(&:protected?) }
        end
      end

      def fetch_memory_cache(key, &payload)
        cache = process_backend.read(key)

        if cache && !stale_cache?(cache)
          cache[:data]
        else
          store_cache(key, &payload)
        end
      end

      def stale_cache?(cache_info)
        shared_timestamp = shared_backend.read(:ci_instance_variable_changed_at)
        return true unless shared_timestamp

        shared_timestamp.to_f > cache_info[:cached_at].to_f
      end

      def store_cache(key)
        data = yield
        time = Time.current.to_f

        process_backend.write(key, data: data, cached_at: time)
        touch_redis_cache_timestamp(time)
        data
      end

      def shared_backend
        Rails.cache
      end

      def process_backend
        Gitlab::ProcessMemoryCache.cache_backend
      end
    end
  end
end
