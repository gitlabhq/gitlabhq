# frozen_string_literal: true

class AddCreatedByForeignKeyToCustomStatuses < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  def up
    add_concurrent_foreign_key :work_item_custom_statuses, :users,
      column: :created_by_id, on_delete: :nullify
  end

  def down
    remove_foreign_key_if_exists :work_item_custom_statuses, column: :created_by_id
  end
end
