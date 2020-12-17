# frozen_string_literal: true

module Gitlab
  module Database
    module Reindexing
      # Number of indexes to reindex per invocation
      DEFAULT_INDEXES_PER_INVOCATION = 2

      # candidate_indexes: Array of Gitlab::Database::PostgresIndex
      def self.perform(candidate_indexes, how_many: DEFAULT_INDEXES_PER_INVOCATION)
        indexes = IndexSelection.new(candidate_indexes).take(how_many)

        Coordinator.new(indexes).perform
      end

      def self.candidate_indexes
        Gitlab::Database::PostgresIndex
          .regular
          .where('NOT expression')
          .not_match("^#{ConcurrentReindex::TEMPORARY_INDEX_PREFIX}")
          .not_match("^#{ConcurrentReindex::REPLACED_INDEX_PREFIX}")
      end
    end
  end
end
