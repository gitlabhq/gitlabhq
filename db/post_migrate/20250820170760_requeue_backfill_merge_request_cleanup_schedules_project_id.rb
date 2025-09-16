# frozen_string_literal: true

class RequeueBackfillMergeRequestCleanupSchedulesProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.4'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillMergeRequestCleanupSchedulesProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  # NOTE: disabling DDL transactions following https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198596#note_2699307408
  disable_ddl_transaction!

  def up
    improved_delete_batched_background_migration(
      MIGRATION,
      :merge_request_cleanup_schedules,
      :merge_request_id,
      [
        :project_id,
        :merge_requests,
        :target_project_id,
        :merge_request_id
      ]
    )

    queue_batched_background_migration(
      MIGRATION,
      :merge_request_cleanup_schedules,
      :merge_request_id,
      :project_id,
      :merge_requests,
      :target_project_id,
      :merge_request_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    improved_delete_batched_background_migration(
      MIGRATION,
      :merge_request_cleanup_schedules,
      :merge_request_id,
      [
        :project_id,
        :merge_requests,
        :target_project_id,
        :merge_request_id
      ]
    )
  end

  private

  # For context on why `delete_batched_background_migration` is overloaded: https://gitlab.com/gitlab-org/gitlab/-/issues/434089#note_2696645957
  def improved_delete_batched_background_migration(job_class_name, table_name, column_name, job_arguments)
    Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.require_dml_mode!

    Gitlab::Database::BackgroundMigration::BatchedMigration.reset_column_information

    batched_migration = Gitlab::Database::BackgroundMigration::BatchedMigration
      .for_configuration(
        gitlab_schema_from_context, job_class_name, table_name, column_name, job_arguments,
        include_compatible: true
      ).take

    return unless batched_migration

    batched_migration.batched_jobs.each_batch(of: 100) { |b| b.delete_all }

    batched_migration.delete
  end
end
