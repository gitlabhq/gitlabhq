# frozen_string_literal: true

class AddNamespaceDeletionSchedulesUserIdFk < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  def up
    add_concurrent_foreign_key :namespace_deletion_schedules, :users, column: :user_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :namespace_deletion_schedules, column: :user_id
    end
  end
end
