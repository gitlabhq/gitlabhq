# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillProtectedBranchMergeAccessLevelsProtectedBranchProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_protected_branch_merge_access_levels_protected_branch_project_id
      feature_category :source_code_management
    end
  end
end
