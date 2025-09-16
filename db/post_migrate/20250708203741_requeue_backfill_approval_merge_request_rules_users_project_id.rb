# frozen_string_literal: true

class RequeueBackfillApprovalMergeRequestRulesUsersProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillApprovalMergeRequestRulesUsersProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    delete_batched_background_migration(
      MIGRATION,
      :approval_merge_request_rules_users,
      :id,
      [
        :project_id,
        :approval_merge_request_rules,
        :project_id,
        :approval_merge_request_rule_id
      ]
    )

    queue_batched_background_migration(
      MIGRATION,
      :approval_merge_request_rules_users,
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
      :approval_merge_request_rules_users,
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
