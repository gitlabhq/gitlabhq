# frozen_string_literal: true

class QueueBackfillApprovalsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillApprovalsProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 5000
  SUB_BATCH_SIZE = 500

  def up
    queue_batched_background_migration(
      MIGRATION,
      :approvals,
      :id,
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
    delete_batched_background_migration(
      MIGRATION,
      :approvals,
      :id,
      [
        :project_id,
        :merge_requests,
        :target_project_id,
        :merge_request_id
      ]
    )
  end
end
