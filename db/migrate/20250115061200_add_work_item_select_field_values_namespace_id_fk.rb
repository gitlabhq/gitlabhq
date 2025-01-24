# frozen_string_literal: true

class AddWorkItemSelectFieldValuesNamespaceIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :work_item_select_field_values, :namespaces,
      column: :namespace_id, on_delete: :cascade, reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :work_item_select_field_values, column: :namespace_id, reverse_lock_order: true
    end
  end
end
