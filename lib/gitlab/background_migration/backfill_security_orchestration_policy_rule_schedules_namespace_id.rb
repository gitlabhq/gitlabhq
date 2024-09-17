# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSecurityOrchestrationPolicyRuleSchedulesNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_security_orchestration_policy_rule_schedules_namespace_id
      feature_category :security_policy_management
    end
  end
end
