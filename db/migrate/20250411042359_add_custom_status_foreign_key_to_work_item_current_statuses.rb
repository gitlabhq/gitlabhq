# frozen_string_literal: true

class AddCustomStatusForeignKeyToWorkItemCurrentStatuses < Gitlab::Database::Migration[2.2]
  milestone '18.0'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :work_item_current_statuses, :work_item_custom_statuses,
      column: :custom_status_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :work_item_current_statuses, column: :custom_status_id
    end
  end
end
