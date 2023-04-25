# frozen_string_literal: true

class AddSecurityOrchestrationPolicyConfigurationNamespaceIndex < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!
  INDEX_NAME = 'partial_index_sop_configs_on_namespace_id'

  def up
    add_concurrent_index :security_orchestration_policy_configurations, :namespace_id, unique: true, name: INDEX_NAME, where: 'namespace_id IS NOT NULL'
    add_concurrent_foreign_key :security_orchestration_policy_configurations, :namespaces, column: :namespace_id, on_delete: :cascade, reverse_lock_order: true

    add_check_constraint :security_orchestration_policy_configurations,
      "((project_id IS NULL) != (namespace_id IS NULL))",
      :cop_configs_project_or_namespace_existence
  end

  def down
    exec_query 'DELETE FROM security_orchestration_policy_configurations WHERE namespace_id IS NOT NULL'

    remove_check_constraint :security_orchestration_policy_configurations, :cop_configs_project_or_namespace_existence

    with_lock_retries do
      remove_foreign_key_if_exists :security_orchestration_policy_configurations, column: :namespace_id
    end

    remove_concurrent_index_by_name :security_orchestration_policy_configurations, INDEX_NAME
  end
end
