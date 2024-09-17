# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillProtectedEnvironmentApprovalRulesProtectedEnvironmentGroupId < BackfillDesiredShardingKeyJob
      operation_name :backfill_protected_environment_approval_rules_protected_environment_group_id
      feature_category :continuous_delivery
    end
  end
end
