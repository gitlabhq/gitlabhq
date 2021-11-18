# frozen_string_literal: true

module Gitlab
  module Database
    module Reindexing
      # Number of indexes to reindex per invocation
      DEFAULT_INDEXES_PER_INVOCATION = 2

      SUPPORTED_TYPES = %w(btree gist).freeze

      # When dropping an index, we acquire a SHARE UPDATE EXCLUSIVE lock,
      # which only conflicts with DDL and vacuum. We therefore execute this with a rather
      # high lock timeout and a long pause in between retries. This is an alternative to
      # setting a high statement timeout, which would lead to a long running query with effects
      # on e.g. vacuum.
      REMOVE_INDEX_RETRY_CONFIG = [[1.minute, 9.minutes]] * 30

      # Performs automatic reindexing for a limited number of indexes per call
      #  1. Consume from the explicit reindexing queue
      #  2. Apply bloat heuristic to find most bloated indexes and reindex those
      def self.automatic_reindexing(maximum_records: DEFAULT_INDEXES_PER_INVOCATION)
        # Cleanup leftover temporary indexes from previous, possibly aborted runs (if any)
        cleanup_leftovers!

        # Consume from the explicit reindexing queue first
        done_counter = perform_from_queue(maximum_records: maximum_records)

        return if done_counter >= maximum_records

        # Execute reindexing based on bloat heuristic
        perform_with_heuristic(maximum_records: maximum_records - done_counter)
      end

      # Reindex based on bloat heuristic for a limited number of indexes per call
      #
      # We use a bloat heuristic to estimate the index bloat and pick the
      # most bloated indexes for reindexing.
      def self.perform_with_heuristic(candidate_indexes = Gitlab::Database::PostgresIndex.reindexing_support, maximum_records: DEFAULT_INDEXES_PER_INVOCATION)
        IndexSelection.new(candidate_indexes).take(maximum_records).each do |index|
          Coordinator.new(index).perform
        end
      end

      # Reindex indexes that have been explicitly enqueued (for a limited number of indexes per call)
      def self.perform_from_queue(maximum_records: DEFAULT_INDEXES_PER_INVOCATION)
        QueuedAction.in_queue_order.limit(maximum_records).each do |queued_entry|
          Coordinator.new(queued_entry.index).perform

          queued_entry.done!
        rescue StandardError => e
          queued_entry.failed!

          Gitlab::AppLogger.error("Failed to perform reindexing action on queued entry #{queued_entry}: #{e}")
        end.size
      end

      def self.cleanup_leftovers!
        PostgresIndex.reindexing_leftovers.each do |index|
          Gitlab::AppLogger.info("Removing index #{index.identifier} which is a leftover, temporary index from previous reindexing activity")

          retries = Gitlab::Database::WithLockRetriesOutsideTransaction.new(
            connection: index.connection,
            timing_configuration: REMOVE_INDEX_RETRY_CONFIG,
            klass: self.class,
            logger: Gitlab::AppLogger
          )

          retries.run(raise_on_exhaustion: false) do
            index.connection.tap do |conn|
              conn.execute("DROP INDEX CONCURRENTLY IF EXISTS #{conn.quote_table_name(index.schema)}.#{conn.quote_table_name(index.name)}")
            end
          end
        end
      end
    end
  end
end
