# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillApprovalGroupRulesProtectedBranchesGroupId < BackfillDesiredShardingKeyJob
      operation_name :backfill_approval_group_rules_protected_branches_group_id
      feature_category :source_code_management
    end
  end
end
