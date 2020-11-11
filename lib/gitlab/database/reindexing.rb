# frozen_string_literal: true

module Gitlab
  module Database
    module Reindexing
      def self.perform(index_selector)
        Coordinator.new(index_selector).perform
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
