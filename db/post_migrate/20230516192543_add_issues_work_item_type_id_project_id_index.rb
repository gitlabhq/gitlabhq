# frozen_string_literal: true

class AddIssuesWorkItemTypeIdProjectIdIndex < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_issues_on_work_item_type_id_project_id_created_at_state'

  disable_ddl_transaction!

  def up
    add_concurrent_index :issues, [:work_item_type_id, :project_id, :created_at, :state_id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :issues, INDEX_NAME
  end
end
