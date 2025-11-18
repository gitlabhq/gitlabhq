# frozen_string_literal: true

class DropNamespaceDeletionSchedulesUserIdFk < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :namespace_deletion_schedules, :users,
        column: :user_id, reverse_lock_order: true
    end
  end

  def down
    add_concurrent_foreign_key :namespace_deletion_schedules, :users,
      column: :user_id, on_delete: :cascade, if_not_exists: true
  end
end
