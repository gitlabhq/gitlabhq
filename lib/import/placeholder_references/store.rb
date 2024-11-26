# frozen_string_literal: true

module Import
  module PlaceholderReferences
    class Store
      CACHE_TTL = 1.day

      def initialize(import_source:, import_uid:)
        @import_source = import_source
        @import_uid = import_uid
      end

      def add(serialized_reference)
        cache.set_add(cache_key, serialized_reference, timeout: CACHE_TTL)
      end

      def get(limit = 1)
        cache.limited_values_from_set(cache_key, limit: limit)
      end

      def remove(values)
        cache.set_remove(cache_key, values)
      end

      def count
        cache.set_count(cache_key)
      end

      def empty?
        count == 0
      end

      def any?
        !empty?
      end

      def clear!
        cache.del(cache_key)
      end

      private

      attr_reader :import_source, :import_uid

      def cache
        Gitlab::Cache::Import::Caching
      end

      def cache_key
        [:'placeholder-references', import_source, import_uid].join(':')
      end
    end
  end
end
