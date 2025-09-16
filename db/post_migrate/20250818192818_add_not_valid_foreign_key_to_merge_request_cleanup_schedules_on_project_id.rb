# frozen_string_literal: true

class AddNotValidForeignKeyToMergeRequestCleanupSchedulesOnProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  def up
    add_concurrent_foreign_key(
      :merge_request_cleanup_schedules,
      :projects,
      column: :project_id,
      on_delete: :cascade,
      validate: false
    )
  end

  def down
    remove_foreign_key_if_exists :merge_request_cleanup_schedules, column: :project_id
  end
end
