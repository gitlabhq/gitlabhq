# frozen_string_literal: true

class ChangeSecurityOrchestrationPolicyConfigurationProjectIndex < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!
  OLD_INDEX_NAME = 'index_sop_configs_on_project_id'
  NEW_INDEX_NAME = 'partial_index_sop_configs_on_project_id'

  def up
    add_concurrent_index :security_orchestration_policy_configurations, :project_id, unique: true, name: NEW_INDEX_NAME, where: 'project_id IS NOT NULL'
    remove_concurrent_index_by_name :security_orchestration_policy_configurations, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :security_orchestration_policy_configurations, :project_id, unique: true, name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :security_orchestration_policy_configurations, NEW_INDEX_NAME
  end
end
