# frozen_string_literal: true

class RemoveWorkItemTypeCustomFieldsWorkItemTypeForeignKey < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key :work_item_type_custom_fields, column: :work_item_type_id
    end
  end

  def down
    add_concurrent_foreign_key :work_item_type_custom_fields, :work_item_types,
      column: :work_item_type_id, on_delete: :cascade
  end
end
