# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillApprovalGroupRulesUsersGroupId < BackfillDesiredShardingKeyJob
      operation_name :backfill_approval_group_rules_users_group_id
      feature_category :source_code_management
    end
  end
end
