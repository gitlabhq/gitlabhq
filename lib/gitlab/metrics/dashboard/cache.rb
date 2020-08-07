# frozen_string_literal: true

require 'set'

module Gitlab
  module Metrics
    module Dashboard
      class Cache
        CACHE_KEYS = 'all_cached_metric_dashboards'

        class << self
          # This class method (Gitlab::Metrics::Dashboard::Cache.fetch) can be used
          # when the key does not need to be deleted by `delete_all!`.
          # For example, out of the box dashboard caches do not need to be deleted.
          delegate :fetch, to: :"Rails.cache"

          alias_method :for, :new
        end

        def initialize(project)
          @project = project
        end

        # Stores a dashboard in the cache, documenting the key
        # so the cache can be cleared in bulk at another time.
        def fetch(key)
          register_key(key)

          Rails.cache.fetch(key) { yield }
        end

        # Resets all dashboard caches, such that all
        # dashboard content will be loaded from source on
        # subsequent dashboard calls.
        def delete_all!
          all_keys.each { |key| Rails.cache.delete(key) }

          Rails.cache.delete(catalog_key)
        end

        private

        def register_key(key)
          new_keys = all_keys.add(key).to_a.join('|')

          Rails.cache.write(catalog_key, new_keys)
        end

        def all_keys
          keys = Rails.cache.read(catalog_key)&.split('|')
          Set.new(keys)
        end

        # One key to store them all...
        # This key is used to store the names of all the keys that contain this
        # project's dashboards.
        def catalog_key
          "#{CACHE_KEYS}_#{@project.id}"
        end
      end
    end
  end
end
