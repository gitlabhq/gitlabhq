# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Background migration for deleting orphaned approval project rules for projects that were transferred
    class DeleteOrphanedTransferredProjectApprovalRules < BatchedMigrationJob
      feature_category :security_policy_management

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::DeleteOrphanedTransferredProjectApprovalRules.prepend_mod
