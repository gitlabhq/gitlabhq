# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class PopulateMergeRequestsLatestMergeRequestDiffId
      BATCH_SIZE = 1_000

      class MergeRequest < ActiveRecord::Base
        self.table_name = 'merge_requests'

        include ::EachBatch
      end

      def perform(start_id, stop_id)
        update = '
          latest_merge_request_diff_id = (
            SELECT MAX(id)
            FROM merge_request_diffs
            WHERE merge_requests.id = merge_request_diffs.merge_request_id
          )'.squish

        MergeRequest
          .where(id: start_id..stop_id)
          .where(latest_merge_request_diff_id: nil)
          .each_batch(of: BATCH_SIZE) do |relation|

          relation.update_all(update)
        end
      end
    end
  end
end
