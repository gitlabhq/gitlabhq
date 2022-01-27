# frozen_string_literal: true

module Gitlab
  class ProcessMemoryCache
    module Helper
      def fetch_memory_cache(key, &payload)
        cache = cache_backend.read(key)

        if cache && !stale_cache?(key, cache)
          cache[:data]
        else
          store_cache(key, &payload)
        end
      end

      def invalidate_memory_cache(key)
        touch_cache_timestamp(key)
      end

      private

      def touch_cache_timestamp(key, time = Time.current.to_f)
        shared_backend.write(key, time)
      end

      def stale_cache?(key, cache_info)
        shared_timestamp = shared_backend.read(key)
        return true unless shared_timestamp

        shared_timestamp.to_f > cache_info[:cached_at].to_f
      end

      def store_cache(key)
        data = yield
        time = Time.current.to_f

        cache_backend.write(key, data: data, cached_at: time)
        touch_cache_timestamp(key, time) unless shared_backend.read(key)
        data
      end

      def shared_backend
        Rails.cache
      end

      def cache_backend
        ::Gitlab::ProcessMemoryCache.cache_backend
      end
    end
  end
end
