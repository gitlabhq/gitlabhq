# frozen_string_literal: true

class DropOldFkForWorkItemTypeCustomFieldsWorkItemTypeId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.10'

  OLD_CONSTRAINT_NAME = 'fk_9447fad7b4'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :work_item_type_custom_fields,
        :work_item_types,
        column: :work_item_type_id,
        on_delete: :cascade,
        name: OLD_CONSTRAINT_NAME
    end
  end

  def down
    add_concurrent_foreign_key :work_item_type_custom_fields,
      :work_item_types,
      column: :work_item_type_id,
      target_column: :correct_id,
      on_delete: :cascade
  end
end
