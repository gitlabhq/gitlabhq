# frozen_string_literal: true

module Gitlab
  module Import
    # PageCounter can be used to keep track of the last imported page of a
    # collection, allowing workers to resume where they left off in the event of
    # an error.
    class PageCounter
      attr_reader :cache_key

      # The base cache key to use for storing the last page number.
      CACHE_KEY = '%{import_type}/page-counter/%{object}/%{collection}'

      def initialize(object, collection, import_type = 'github-importer')
        @cache_key = format(CACHE_KEY, import_type: import_type, object: object.id, collection: collection)
      end

      # Sets the page number to the given value.
      #
      # Returns true if the page number was overwritten, false otherwise.
      def set(page)
        Gitlab::Cache::Import::Caching.write_if_greater(cache_key, page)
      end

      # Returns the current value from the cache.
      def current
        Gitlab::Cache::Import::Caching.read_integer(cache_key) || 1
      end

      def expire!
        Gitlab::Cache::Import::Caching.expire(cache_key, 0)
      end
    end
  end
end
