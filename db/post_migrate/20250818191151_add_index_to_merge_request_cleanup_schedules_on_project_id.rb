# frozen_string_literal: true

class AddIndexToMergeRequestCleanupSchedulesOnProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  INDEX_NAME = 'index_merge_request_cleanup_schedules_on_project_id'

  def up
    # NOTE: the index was created in https://gitlab.com/gitlab-org/gitlab/-/commit/d97485474fe4af3423543a3c3d399f2d3360534a
    add_concurrent_index :merge_request_cleanup_schedules, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :merge_request_cleanup_schedules, name: INDEX_NAME
  end
end
