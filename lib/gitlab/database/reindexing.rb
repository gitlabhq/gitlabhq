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

      # candidate_indexes: Array of Gitlab::Database::PostgresIndex
      def self.perform(candidate_indexes, how_many: DEFAULT_INDEXES_PER_INVOCATION)
        IndexSelection.new(candidate_indexes).take(how_many).each do |index|
          Coordinator.new(index).perform
        end
      end

      def self.cleanup_leftovers!
        PostgresIndex.reindexing_leftovers.each do |index|
          Gitlab::AppLogger.info("Removing index #{index.identifier} which is a leftover, temporary index from previous reindexing activity")

          retries = Gitlab::Database::WithLockRetriesOutsideTransaction.new(
            timing_configuration: REMOVE_INDEX_RETRY_CONFIG,
            klass: self.class,
            logger: Gitlab::AppLogger
          )

          retries.run(raise_on_exhaustion: false) do
            ApplicationRecord.connection.tap do |conn|
              conn.execute("DROP INDEX CONCURRENTLY IF EXISTS #{conn.quote_table_name(index.schema)}.#{conn.quote_table_name(index.name)}")
            end
          end
        end
      end
    end
  end
end
