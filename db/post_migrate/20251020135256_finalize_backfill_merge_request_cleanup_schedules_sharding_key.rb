# frozen_string_literal: true

class FinalizeBackfillMergeRequestCleanupSchedulesShardingKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  milestone '18.6'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillMergeRequestCleanupSchedulesProjectId',
      table_name: :merge_request_cleanup_schedules,
      column_name: :merge_request_id,
      job_arguments: [
        :project_id,
        :merge_requests,
        :target_project_id,
        :merge_request_id
      ],
      finalize: true
    )
  end

  def down; end
end
