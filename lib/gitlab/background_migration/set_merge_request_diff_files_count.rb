# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Sets the MergeRequestDiff#files_count value for old rows
    class SetMergeRequestDiffFilesCount
      # Some historic data has a *lot* of files. Apply a sentinel to these cases
      FILES_COUNT_SENTINEL = 2**15 - 1

      def self.count_subquery
        <<~SQL
          files_count = (
            SELECT LEAST(#{FILES_COUNT_SENTINEL}, count(*))
            FROM merge_request_diff_files
            WHERE merge_request_diff_files.merge_request_diff_id = merge_request_diffs.id
          )
        SQL
      end

      class MergeRequestDiff < ActiveRecord::Base # rubocop:disable Style/Documentation
        include EachBatch

        self.table_name = 'merge_request_diffs'
      end

      def perform(start_id, end_id)
        MergeRequestDiff.where(id: start_id..end_id).each_batch do |relation|
          relation.update_all(self.class.count_subquery)
        end
      end
    end
  end
end
