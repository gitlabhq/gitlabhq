# frozen_string_literal: true

class DeleteOrphansApprovalMergeRequestRules2 < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MERGE_REQUEST_MIGRATION = 'DeleteOrphansApprovalMergeRequestRules2'
  INTERVAL = 2.minutes

  def up
    queue_batched_background_migration(
      MERGE_REQUEST_MIGRATION,
      :approval_merge_request_rules,
      :id,
      job_interval: INTERVAL,
      batch_size: 2500,
      sub_batch_size: 500
    )
  end

  def down
    delete_batched_background_migration(MERGE_REQUEST_MIGRATION, :approval_merge_request_rules, :id, [])
  end
end
