# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillApprovalProjectRulesUsersProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_approval_project_rules_users_project_id
      feature_category :source_code_management
    end
  end
end
