# frozen_string_literal: true

module Gitlab
  module Database
    module Reindexing
      def self.perform(index_selector)
        Array.wrap(index_selector).each do |index|
          ReindexAction.keep_track_of(index) do
            ConcurrentReindex.new(index).perform
          end
        end
      end

      def self.candidate_indexes
        Gitlab::Database::PostgresIndex
          .regular
          .not_match("^#{ConcurrentReindex::TEMPORARY_INDEX_PREFIX}")
          .not_match("^#{ConcurrentReindex::REPLACED_INDEX_PREFIX}")
      end
    end
  end
end
