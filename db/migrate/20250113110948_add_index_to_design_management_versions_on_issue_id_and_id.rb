# frozen_string_literal: true

class AddIndexToDesignManagementVersionsOnIssueIdAndId < Gitlab::Database::Migration[2.2]
  INDEX_NAME = "index_design_management_versions_on_issue_id_and_id"
  EXISTING_INDEX_NAME = 'index_design_management_versions_on_issue_id'

  milestone '17.9'
  disable_ddl_transaction!

  def up
    add_concurrent_index :design_management_versions, [:issue_id, :id], name: INDEX_NAME
    remove_concurrent_index_by_name(:design_management_versions, EXISTING_INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name :design_management_versions, INDEX_NAME
    add_concurrent_index :design_management_versions, :issue_id, name: EXISTING_INDEX_NAME
  end
end
