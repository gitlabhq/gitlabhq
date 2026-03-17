# frozen_string_literal: true

class RemoveForeignKeyFromWorkItemTypeCustomLifecycles < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'fk_111d417cb7'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :work_item_type_custom_lifecycles, :work_item_types,
        column: :work_item_type_id, name: CONSTRAINT_NAME
    end
  end

  def down
    add_concurrent_foreign_key :work_item_type_custom_lifecycles, :work_item_types,
      column: :work_item_type_id, on_delete: :cascade, name: CONSTRAINT_NAME
  end
end
