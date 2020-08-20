# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Sets the MergeRequestDiff#files_count value for old rows
    class SetMergeRequestDiffFilesCount
      COUNT_SUBQUERY = <<~SQL
        files_count = (
          SELECT count(*)
          FROM merge_request_diff_files
          WHERE merge_request_diff_files.merge_request_diff_id = merge_request_diffs.id
        )
      SQL

      class MergeRequestDiff < ActiveRecord::Base # rubocop:disable Style/Documentation
        include EachBatch

        self.table_name = 'merge_request_diffs'
      end

      def perform(start_id, end_id)
        MergeRequestDiff.where(id: start_id..end_id).each_batch do |relation|
          relation.update_all(COUNT_SUBQUERY)
        end
      end
    end
  end
end
