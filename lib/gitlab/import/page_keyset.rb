# frozen_string_literal: true

module Gitlab
  module Import
    # PageKeyset can be used to keep track of the last imported page of a
    # collection, allowing workers to resume where they left off in the event of
    # an error.
    class PageKeyset
      attr_reader :cache_key

      # The base cache key to use for storing the last key.
      CACHE_KEY = '%{import_type}/page-keyset/%{object}/%{collection}'

      def initialize(object, collection, import_type)
        @cache_key = format(CACHE_KEY, import_type: import_type, object: object.id, collection: collection)
      end

      # Set the key to the given value.
      #
      # @param value [String]
      # @return [String]
      def set(value)
        Gitlab::Cache::Import::Caching.write(cache_key, value)
      end

      # Get the current value from the cache
      #
      # @return [String]
      def current
        Gitlab::Cache::Import::Caching.read(cache_key)
      end

      # Expire the key
      #
      # @return [Boolean]
      def expire!
        Gitlab::Cache::Import::Caching.expire(cache_key, 0)
      end
    end
  end
end
