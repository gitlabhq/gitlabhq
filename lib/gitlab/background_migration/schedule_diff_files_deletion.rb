# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class ScheduleDiffFilesDeletion
      class MergeRequestDiff < ActiveRecord::Base
        self.table_name = 'merge_request_diffs'

        belongs_to :merge_request

        include EachBatch
      end

      DIFF_BATCH_SIZE = 5_000
      INTERVAL = 5.minutes
      MIGRATION = 'DeleteDiffFiles'

      def perform
        diffs = MergeRequestDiff
          .from("(#{diffs_collection.to_sql}) merge_request_diffs")
          .where('merge_request_diffs.id != merge_request_diffs.latest_merge_request_diff_id')
          .select(:id)

        diffs.each_batch(of: DIFF_BATCH_SIZE) do |relation, index|
          ids = relation.pluck(:id)

          BackgroundMigrationWorker.perform_in(index * INTERVAL, MIGRATION, [ids])
        end
      end

      private

      def diffs_collection
        MergeRequestDiff
          .joins(:merge_request)
          .where("merge_requests.state = 'merged'")
          .where('merge_requests.latest_merge_request_diff_id IS NOT NULL')
          .where("merge_request_diffs.state NOT IN ('without_files', 'empty')")
          .select('merge_requests.latest_merge_request_diff_id, merge_request_diffs.id')
      end
    end
  end
end
