# frozen_string_literal: true

module Banzai
  module RequestStoreReferenceCache
    def cached_call(request_store_key, cache_key, path: [])
      if Gitlab::SafeRequestStore.active?
        cache = Gitlab::SafeRequestStore[request_store_key] ||= Hash.new do |hash, key|
          hash[key] = Hash.new { |h, k| h[k] = {} }
        end

        cache = cache.dig(*path) if path.any?

        get_or_set_cache(cache, cache_key) { yield }
      else
        yield
      end
    end

    def get_or_set_cache(cache, key)
      if cache.key?(key)
        cache[key]
      else
        value = yield
        cache[key] = value if key.present?
        value
      end
    end
  end
end
