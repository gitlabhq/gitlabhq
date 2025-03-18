# frozen_string_literal: true

class NewFkForWorkItemTypeCustomFieldsWorkItemTypeId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.10'

  NEW_CONSTRAINT_NAME = 'fk_work_item_type_custom_fields_on_work_item_type_id'

  def up
    add_concurrent_foreign_key :work_item_type_custom_fields,
      :work_item_types,
      column: :work_item_type_id,
      name: NEW_CONSTRAINT_NAME
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :work_item_type_custom_fields,
        :work_item_types,
        column: :work_item_type_id,
        name: NEW_CONSTRAINT_NAME
    end
  end
end
