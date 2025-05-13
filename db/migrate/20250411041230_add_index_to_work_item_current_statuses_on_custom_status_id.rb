# frozen_string_literal: true

class AddIndexToWorkItemCurrentStatusesOnCustomStatusId < Gitlab::Database::Migration[2.2]
  milestone '18.0'
  disable_ddl_transaction!

  INDEX_NAME = 'index_work_item_current_statuses_on_custom_status_id'

  def up
    add_concurrent_index :work_item_current_statuses, :custom_status_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :work_item_current_statuses, name: INDEX_NAME
  end
end
