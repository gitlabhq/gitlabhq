# frozen_string_literal: true

class RemoveForeignKeyFromWorkItemTypeCustomFields < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'fk_work_item_type_custom_fields_on_work_item_type_id'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :work_item_type_custom_fields, :work_item_types,
        column: :work_item_type_id, name: CONSTRAINT_NAME
    end
  end

  def down
    add_concurrent_foreign_key :work_item_type_custom_fields, :work_item_types,
      column: :work_item_type_id, on_delete: :cascade, name: CONSTRAINT_NAME
  end
end
