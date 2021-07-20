# frozen_string_literal: true

module Gitlab
  module Database
    module Reindexing
      # Number of indexes to reindex per invocation
      DEFAULT_INDEXES_PER_INVOCATION = 2

      SUPPORTED_TYPES = %w(btree gist).freeze

      # candidate_indexes: Array of Gitlab::Database::PostgresIndex
      def self.perform(candidate_indexes, how_many: DEFAULT_INDEXES_PER_INVOCATION)
        IndexSelection.new(candidate_indexes).take(how_many).each do |index|
          Coordinator.new(index).perform
        end
      end

      def self.candidate_indexes
        Gitlab::Database::PostgresIndex
          .not_match("#{ReindexConcurrently::TEMPORARY_INDEX_PATTERN}$")
          .reindexing_support
      end
    end
  end
end
