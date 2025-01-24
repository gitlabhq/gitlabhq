# frozen_string_literal: true

class AddWorkItemTextFieldValuesWorkItemIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :work_item_text_field_values, :issues,
      column: :work_item_id, on_delete: :cascade, reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :work_item_text_field_values, column: :work_item_id, reverse_lock_order: true
    end
  end
end
