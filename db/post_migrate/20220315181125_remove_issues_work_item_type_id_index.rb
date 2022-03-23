# frozen_string_literal: true

class RemoveIssuesWorkItemTypeIdIndex < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_issues_on_work_item_type_id'

  def up
    remove_concurrent_index_by_name :issues, name: INDEX_NAME
  end

  def down
    add_concurrent_index :issues, :work_item_type_id, name: INDEX_NAME
  end
end
