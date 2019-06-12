# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Updates the range of given MRs to merge_status "unchecked", if they're opened
    # and mergeable.
    class ResetMergeStatus
      def perform(from_id, to_id)
        relation = MergeRequest.where(id: from_id..to_id,
                                      state: 'opened',
                                      merge_status: 'can_be_merged')

        relation.update_all(merge_status: 'unchecked')
      end
    end
  end
end
