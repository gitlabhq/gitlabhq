# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Cleanup draft column data inserted by a faulty regex
    #
    class CleanupDraftDataFromFaultyRegex
      # Migration only version of MergeRequest table
      ##
      class MergeRequest < ActiveRecord::Base
        LEAKY_REGEXP_STR     = "^\\[draft\\]|\\(draft\\)|draft:|draft|\\[WIP\\]|WIP:|WIP"
        CORRECTED_REGEXP_STR = "^(\\[draft\\]|\\(draft\\)|draft:|draft|\\[WIP\\]|WIP:|WIP)"

        include EachBatch

        self.table_name = 'merge_requests'

        def self.eligible
          where(state_id: 1)
            .where(draft: true)
            .where("title ~* ?", LEAKY_REGEXP_STR)
            .where("title !~* ?", CORRECTED_REGEXP_STR)
        end
      end

      def perform(start_id, end_id)
        eligible_mrs = MergeRequest.eligible.where(id: start_id..end_id).pluck(:id)

        return if eligible_mrs.empty?

        eligible_mrs.each_slice(10) do |slice|
          MergeRequest.where(id: slice).update_all(draft: false)
        end

        mark_job_as_succeeded(start_id, end_id)
      end

      private

      def mark_job_as_succeeded(*arguments)
        Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
          'CleanupDraftDataFromFaultyRegex',
          arguments
        )
      end
    end
  end
end
