# frozen_string_literal: true

class PrepareIndexMergeRequestCleanupSchedulesOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  INDEX_NAME = 'index_merge_request_cleanup_schedules_on_project_id'

  def up
    prepare_async_index :merge_request_cleanup_schedules, :project_id, name: INDEX_NAME
  end

  def down
    unprepare_async_index :merge_request_cleanup_schedules, INDEX_NAME
  end
end
