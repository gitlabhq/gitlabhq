# frozen_string_literal: true

class RemoveProjectDeletionSchedulesUserIdFk < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  def up
    with_lock_retries do
      remove_foreign_key :project_deletion_schedules, :users
    end
  end

  def down
    add_concurrent_foreign_key :project_deletion_schedules, :users, column: :user_id
  end
end
