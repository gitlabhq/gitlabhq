# frozen_string_literal: true

class AddWorkItemTypeCustomFieldsCustomFieldForeignKey < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :work_item_type_custom_fields, :custom_fields,
      column: :custom_field_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :work_item_type_custom_fields, column: :custom_field_id
    end
  end
end
