# frozen_string_literal: true

class AddWorkItemTypeCustomFieldsCorrectWorkItemTypeForeignKey < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :work_item_type_custom_fields, :work_item_types,
      column: :work_item_type_id, target_column: :correct_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :work_item_type_custom_fields, column: :work_item_type_id
    end
  end
end
