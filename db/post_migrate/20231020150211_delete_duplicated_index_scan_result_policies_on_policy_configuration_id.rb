# frozen_string_literal: true

class DeleteDuplicatedIndexScanResultPoliciesOnPolicyConfigurationId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_scan_result_policies_on_policy_configuration_id'
  COLUMNS = %i[security_orchestration_policy_configuration_id]

  def up
    remove_concurrent_index_by_name :scan_result_policies, INDEX_NAME
  end

  def down
    add_concurrent_index :scan_result_policies, COLUMNS, name: INDEX_NAME
  end
end
