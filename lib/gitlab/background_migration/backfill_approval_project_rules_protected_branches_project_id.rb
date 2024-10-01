# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillApprovalProjectRulesProtectedBranchesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_approval_project_rules_protected_branches_project_id
      feature_category :source_code_management
    end
  end
end
