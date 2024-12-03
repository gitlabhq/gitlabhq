# frozen_string_literal: true

class ReplaceUniqueIndexOnScanResultPolicies < Gitlab::Database::Migration[2.2]
  REMOVED_INDEX_NAME = "index_scan_result_policies_on_position_in_configuration"
  ADDED_INDEX_NAME = "index_scan_result_policies_on_configuration_action_and_rule_idx"

  disable_ddl_transaction!

  milestone '17.7'

  def up
    add_concurrent_index :scan_result_policies,
      %i[security_orchestration_policy_configuration_id project_id orchestration_policy_idx rule_idx action_idx],
      unique: true,
      name: ADDED_INDEX_NAME
    remove_concurrent_index_by_name :scan_result_policies, name: REMOVED_INDEX_NAME
  end

  def down
    add_concurrent_index :scan_result_policies,
      %i[security_orchestration_policy_configuration_id project_id orchestration_policy_idx rule_idx],
      unique: true,
      name: REMOVED_INDEX_NAME
    remove_concurrent_index_by_name :scan_result_policies, name: ADDED_INDEX_NAME
  end
end
