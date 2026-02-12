# frozen_string_literal: true

class DropWorkItemCustomTypesNamespaceFk < Gitlab::Database::Migration[2.3]
  milestone '18.9'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :work_item_custom_types, column: :namespace_id
    end
  end

  def down
    add_concurrent_foreign_key :work_item_custom_types,
      :namespaces,
      column: :namespace_id,
      target_column: :id
  end
end
