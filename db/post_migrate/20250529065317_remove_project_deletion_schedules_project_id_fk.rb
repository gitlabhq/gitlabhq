# frozen_string_literal: true

class RemoveProjectDeletionSchedulesProjectIdFk < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  def up
    with_lock_retries do
      remove_foreign_key :project_deletion_schedules, :projects
    end
  end

  def down
    add_concurrent_foreign_key :project_deletion_schedules, :projects, column: :project_id
  end
end
