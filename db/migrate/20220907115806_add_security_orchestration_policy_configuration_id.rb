# frozen_string_literal: true

class AddSecurityOrchestrationPolicyConfigurationId < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  PROJECT_INDEX_NAME = 'idx_approval_project_rules_on_sec_orchestration_config_id'
  MERGE_REQUEST_INDEX_NAME = 'idx_approval_merge_request_rules_on_sec_orchestration_config_id'

  def up
    with_lock_retries do
      unless column_exists?(:approval_project_rules, :security_orchestration_policy_configuration_id)
        add_column :approval_project_rules, :security_orchestration_policy_configuration_id, :bigint
      end
    end

    with_lock_retries do
      unless column_exists?(:approval_merge_request_rules, :security_orchestration_policy_configuration_id)
        add_column :approval_merge_request_rules, :security_orchestration_policy_configuration_id, :bigint
      end
    end

    add_concurrent_index :approval_project_rules,
      :security_orchestration_policy_configuration_id,
      name: PROJECT_INDEX_NAME
    add_concurrent_index :approval_merge_request_rules,
      :security_orchestration_policy_configuration_id,
      name: MERGE_REQUEST_INDEX_NAME

    add_concurrent_foreign_key :approval_project_rules,
      :security_orchestration_policy_configurations,
      column: :security_orchestration_policy_configuration_id,
      on_delete: :cascade
    add_concurrent_foreign_key :approval_merge_request_rules,
      :security_orchestration_policy_configurations,
      column: :security_orchestration_policy_configuration_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      if column_exists?(:approval_project_rules, :security_orchestration_policy_configuration_id)
        remove_column :approval_project_rules, :security_orchestration_policy_configuration_id
      end
    end

    with_lock_retries do
      if column_exists?(:approval_merge_request_rules, :security_orchestration_policy_configuration_id)
        remove_column :approval_merge_request_rules, :security_orchestration_policy_configuration_id
      end
    end

    remove_foreign_key_if_exists :approval_project_rules, column: :security_orchestration_policy_configuration_id
    remove_foreign_key_if_exists :approval_merge_request_rules, column: :security_orchestration_policy_configuration_id

    remove_concurrent_index_by_name :approval_project_rules, name: PROJECT_INDEX_NAME
    remove_concurrent_index_by_name :approval_merge_request_rules, name: MERGE_REQUEST_INDEX_NAME
  end
end
