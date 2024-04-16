# frozen_string_literal: true

class AddIndexScanResultPoliciesOnConfigurationIdAndIdAndUpdatedAt < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  disable_ddl_transaction!

  INDEX_NAME = :idx_scan_result_policies_on_configuration_id_id_updated_at
  TABLE_NAME = :scan_result_policies

  def up
    add_concurrent_index(TABLE_NAME, %i[security_orchestration_policy_configuration_id id updated_at], name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
