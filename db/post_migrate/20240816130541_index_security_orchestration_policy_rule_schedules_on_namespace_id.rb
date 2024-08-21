# frozen_string_literal: true

class IndexSecurityOrchestrationPolicyRuleSchedulesOnNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  disable_ddl_transaction!

  INDEX_NAME = 'index_security_orchestration_policy_rule_schedules_on_namespace'

  def up
    add_concurrent_index :security_orchestration_policy_rule_schedules, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :security_orchestration_policy_rule_schedules, INDEX_NAME
  end
end
