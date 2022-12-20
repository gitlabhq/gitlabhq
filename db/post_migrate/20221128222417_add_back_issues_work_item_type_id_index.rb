# frozen_string_literal: true

class AddBackIssuesWorkItemTypeIdIndex < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_issues_on_work_item_type_id'

  def up
    prepare_async_index :issues, :work_item_type_id, name: INDEX_NAME
  end

  def down
    unprepare_async_index :issues, :work_item_type_id, name: INDEX_NAME
  end
end
