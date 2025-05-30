# frozen_string_literal: true

class AddNamespaceDeletionSchedulesNamespaceIdFk < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  def up
    add_concurrent_foreign_key :namespace_deletion_schedules, :namespaces, column: :namespace_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :namespace_deletion_schedules, column: :namespace_id
    end
  end
end
