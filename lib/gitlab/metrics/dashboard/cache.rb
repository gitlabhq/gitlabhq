# frozen_string_literal: true

require 'set'

module Gitlab
  module Metrics
    module Dashboard
      class Cache
        CACHE_KEYS = 'all_cached_metric_dashboards'

        class << self
          # Stores a dashboard in the cache, documenting the key
          # so the cached can be cleared in bulk at another time.
          def fetch(key)
            register_key(key)

            Rails.cache.fetch(key) { yield }
          end

          # Resets all dashboard caches, such that all
          # dashboard content will be loaded from source on
          # subsequent dashboard calls.
          def delete_all!
            all_keys.each { |key| Rails.cache.delete(key) }

            Rails.cache.delete(CACHE_KEYS)
          end

          private

          def register_key(key)
            new_keys = all_keys.add(key).to_a.join('|')

            Rails.cache.write(CACHE_KEYS, new_keys)
          end

          def all_keys
            Set.new(Rails.cache.read(CACHE_KEYS)&.split('|'))
          end
        end
      end
    end
  end
end
