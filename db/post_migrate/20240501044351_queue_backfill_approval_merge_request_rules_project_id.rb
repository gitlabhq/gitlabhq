# frozen_string_literal: true

class QueueBackfillApprovalMergeRequestRulesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.0'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillApprovalMergeRequestRulesProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :approval_merge_request_rules,
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
      :approval_merge_request_rules,
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
