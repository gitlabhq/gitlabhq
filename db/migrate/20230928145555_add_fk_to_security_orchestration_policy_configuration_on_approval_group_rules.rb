# frozen_string_literal: true

class AddFkToSecurityOrchestrationPolicyConfigurationOnApprovalGroupRules < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :approval_group_rules, :security_orchestration_policy_configurations,
      column: :security_orchestration_policy_configuration_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :approval_group_rules,
        column: :security_orchestration_policy_configuration_id
    end
  end
end
