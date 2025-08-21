# frozen_string_literal: true

class QueueBackfillDeploymentMergeRequestsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillDeploymentMergeRequestsProjectId"
  STRATEGY = 'PrimaryKeyBatchingStrategy'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    max_deployment_id = define_batchable_model('deployment_merge_requests').maximum(:deployment_id)
    max_merge_request_id = define_batchable_model('deployment_merge_requests').maximum(:merge_request_id)

    max_deployment_id ||= 0
    max_merge_request_id ||= 0

    Gitlab::Database::BackgroundMigration::BatchedMigration.create!(
      gitlab_schema: :gitlab_main_org,
      job_class_name: MIGRATION,
      job_arguments: [
        :project_id,
        :deployments,
        :project_id,
        :deployment_id
      ],
      table_name: :deployment_merge_requests,
      column_name: :deployment_id,
      min_cursor: [0, 0],
      max_cursor: [max_deployment_id, max_merge_request_id],
      interval: DELAY_INTERVAL,
      pause_ms: 100,
      batch_class_name: STRATEGY,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      status_event: :execute
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :deployment_merge_requests,
      :deployment_id,
      [
        :project_id,
        :deployments,
        :project_id,
        :deployment_id
      ]
    )
  end
end
