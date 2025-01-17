# frozen_string_literal: true

class AddIndexToDesignManagementDesingsOnIssueIdAndId < Gitlab::Database::Migration[2.2]
  INDEX_NAME = "index_on_design_management_designs_issue_id_and_id"

  milestone '17.9'
  disable_ddl_transaction!

  def up
    add_concurrent_index :design_management_designs, [:issue_id, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :design_management_designs, INDEX_NAME
  end
end
