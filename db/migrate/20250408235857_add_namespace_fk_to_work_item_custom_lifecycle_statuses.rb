# frozen_string_literal: true

class AddNamespaceFkToWorkItemCustomLifecycleStatuses < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  def up
    add_concurrent_foreign_key :work_item_custom_lifecycle_statuses, :namespaces,
      column: :namespace_id, on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :work_item_custom_lifecycle_statuses, column: :namespace_id
  end
end
