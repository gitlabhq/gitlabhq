# frozen_string_literal: true

class AddIndexToScanResultPoliciesOnProjectId < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_scan_result_policies_on_project_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :scan_result_policies, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :scan_result_policies, INDEX_NAME
  end
end
