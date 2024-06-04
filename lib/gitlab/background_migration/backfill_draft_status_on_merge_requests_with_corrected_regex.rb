# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfill draft column on open merge requests based on regex parsing of
    #   their titles.
    #
    class BackfillDraftStatusOnMergeRequestsWithCorrectedRegex # rubocop:disable Migration/BatchedMigrationBaseClass
      # Migration only version of MergeRequest table
      class MergeRequest < ::ApplicationRecord
        include EachBatch
        validates :suggested_reviewers, json_schema: { filename: 'merge_request_suggested_reviewers' }

        CORRECTED_REGEXP_STR = "^(\\[draft\\]|\\(draft\\)|draft:|draft|\\[WIP\\]|WIP:|WIP)"

        self.table_name = 'merge_requests'

        def self.eligible
          where(state_id: 1)
            .where(draft: false)
            .where("title ~* ?", CORRECTED_REGEXP_STR)
        end
      end

      def perform(start_id, end_id)
        eligible_mrs = MergeRequest.eligible.where(id: start_id..end_id).pluck(:id)

        eligible_mrs.each_slice(10) do |slice|
          MergeRequest.where(id: slice).update_all(draft: true)
        end

        mark_job_as_succeeded(start_id, end_id)
      end

      private

      def mark_job_as_succeeded(*arguments)
        Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
          'BackfillDraftStatusOnMergeRequestsWithCorrectedRegex',
          arguments
        )
      end
    end
  end
end
