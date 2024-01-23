# frozen_string_literal: true

module BulkImports
  class ObjectCounter
    SOURCE_COUNTER = :source
    FETCHED_COUNTER = :fetched
    IMPORTED_COUNTER = :imported
    COUNTER_TYPES = [SOURCE_COUNTER, FETCHED_COUNTER, IMPORTED_COUNTER].freeze
    CACHE_KEY = 'bulk_imports/object_counter/%{tracker_id}'

    class << self
      def increment(tracker, counter_type, value = 1)
        return unless valid_input?(counter_type, value)

        Gitlab::Cache::Import::Caching.hash_increment(counter_key(tracker), counter_type, value)
      end

      def set(tracker, counter_type, value = 1)
        return unless valid_input?(counter_type, value)

        Gitlab::Cache::Import::Caching.hash_add(counter_key(tracker), counter_type, value)
      end

      def summary(tracker)
        object_counters = Gitlab::Cache::Import::Caching.values_from_hash(counter_key(tracker))

        return unless object_counters.is_a?(Hash)
        return if object_counters.empty?

        empty_response.merge(object_counters.symbolize_keys.transform_values(&:to_i))
      end

      # Commits counters from redis to the database
      def persist!(tracker)
        counters = summary(tracker)

        return unless counters

        tracker.update!(
          source_objects_count: counters[SOURCE_COUNTER],
          fetched_objects_count: counters[FETCHED_COUNTER],
          imported_objects_count: counters[IMPORTED_COUNTER]
        )
      end

      private

      def counter_key(tracker)
        Kernel.format(CACHE_KEY, tracker_id: tracker.id)
      end

      def valid_input?(counter_type, value)
        return false unless value.is_a?(Integer)
        return false if value <= 0
        return false unless COUNTER_TYPES.include?(counter_type)

        true
      end

      def empty_response
        {
          SOURCE_COUNTER => 0,
          FETCHED_COUNTER => 0,
          IMPORTED_COUNTER => 0
        }
      end
    end
  end
end
