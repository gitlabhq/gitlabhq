# frozen_string_literal: true

class AddNamespaceIdFkToWorkItemTypeVisibilityDefaults < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :work_item_type_visibility_defaults, :namespaces,
      column: :namespace_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :work_item_type_visibility_defaults, column: :namespace_id
    end
  end
end
