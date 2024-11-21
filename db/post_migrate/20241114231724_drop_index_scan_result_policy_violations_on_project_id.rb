# frozen_string_literal: true

class DropIndexScanResultPolicyViolationsOnProjectId < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'index_scan_result_policy_violations_on_project_id'

  disable_ddl_transaction!
  milestone '17.7'

  def up
    remove_concurrent_index_by_name :scan_result_policy_violations, INDEX_NAME
  end

  def down
    add_concurrent_index :scan_result_policy_violations, :project_id, name: INDEX_NAME
  end
end
