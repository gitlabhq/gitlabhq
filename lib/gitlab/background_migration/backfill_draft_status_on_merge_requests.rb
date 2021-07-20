# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfill draft column on open merge requests based on regex parsing of
    #   their titles.
    #
    class BackfillDraftStatusOnMergeRequests
      # Migration only version of MergeRequest table
      class MergeRequest < ActiveRecord::Base
        include EachBatch

        self.table_name = 'merge_requests'

        def self.eligible
          where(state_id: 1)
            .where(draft: false)
            .where("title ~* ?", '^\\[draft\\]|\\(draft\\)|draft:|draft|\\[WIP\\]|WIP:|WIP')
        end
      end

      def perform(start_id, end_id)
        eligible_mrs = MergeRequest.eligible.where(id: start_id..end_id).pluck(:id)

        return if eligible_mrs.empty?

        eligible_mrs.each_slice(10) do |slice|
          MergeRequest.where(id: slice).update_all(draft: true)
        end
      end
    end
  end
end
