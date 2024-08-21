# frozen_string_literal: true

class AddSecurityOrchestrationPolicyRuleSchedulesNamespaceIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :security_orchestration_policy_rule_schedules, :namespaces, column: :namespace_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :security_orchestration_policy_rule_schedules, column: :namespace_id
    end
  end
end
