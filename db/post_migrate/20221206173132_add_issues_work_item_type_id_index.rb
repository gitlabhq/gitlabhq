# frozen_string_literal: true

class AddIssuesWorkItemTypeIdIndex < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_issues_on_work_item_type_id'

  def up
    add_concurrent_index :issues, :work_item_type_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :issues, INDEX_NAME
  end
end
