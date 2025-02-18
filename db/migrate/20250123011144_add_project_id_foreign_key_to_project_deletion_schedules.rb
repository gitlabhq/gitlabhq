# frozen_string_literal: true

class AddProjectIdForeignKeyToProjectDeletionSchedules < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.7'

  def up
    add_concurrent_foreign_key :project_deletion_schedules, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :project_deletion_schedules, column: :project_id
    end
  end
end
