# frozen_string_literal: true

class AddUniqueIndexToScanResultPoliciesOnPositionInConfiguration < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_scan_result_policies_on_position_in_configuration'
  COLUMNS = %i[security_orchestration_policy_configuration_id project_id orchestration_policy_idx rule_idx]

  def up
    add_concurrent_index :scan_result_policies, COLUMNS, unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :scan_result_policies, INDEX_NAME
  end
end
