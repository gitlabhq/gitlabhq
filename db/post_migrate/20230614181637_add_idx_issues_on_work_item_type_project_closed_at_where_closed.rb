# frozen_string_literal: true

class AddIdxIssuesOnWorkItemTypeProjectClosedAtWhereClosed < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'idx_issues_on_project_work_item_type_closed_at_where_closed'

  disable_ddl_transaction!

  def up
    add_concurrent_index :issues, [:project_id, :work_item_type_id, :closed_at], where: 'state_id = 2', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :issues, INDEX_NAME
  end
end
