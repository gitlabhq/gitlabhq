# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This background migration creates any approver rule records according
    # to the given merge request IDs range. A _single_ INSERT is issued for the given range.
    class PopulateAnyApprovalRuleForMergeRequests
      def perform(from_id, to_id)
      end
    end
  end
end

Gitlab::BackgroundMigration::PopulateAnyApprovalRuleForMergeRequests.prepend_mod_with('Gitlab::BackgroundMigration::PopulateAnyApprovalRuleForMergeRequests')
