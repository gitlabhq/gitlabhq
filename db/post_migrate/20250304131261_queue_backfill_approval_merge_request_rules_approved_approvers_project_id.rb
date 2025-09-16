# frozen_string_literal: true

class QueueBackfillApprovalMergeRequestRulesApprovedApproversProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillApprovalMergeRequestRulesApprovedApproversProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :approval_merge_request_rules_approved_approvers,
      :id,
      :project_id,
      :approval_merge_request_rules,
      :project_id,
      :approval_merge_request_rule_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :approval_merge_request_rules_approved_approvers,
      :id,
      [
        :project_id,
        :approval_merge_request_rules,
        :project_id,
        :approval_merge_request_rule_id
      ]
    )
  end
end
