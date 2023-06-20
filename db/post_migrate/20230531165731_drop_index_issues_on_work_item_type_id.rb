# frozen_string_literal: true

class DropIndexIssuesOnWorkItemTypeId < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_issues_on_work_item_type_id'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :issues, INDEX_NAME
  end

  def down
    add_concurrent_index :issues, :work_item_type_id, name: INDEX_NAME
  end
end
