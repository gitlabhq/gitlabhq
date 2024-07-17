# frozen_string_literal: true

class QueueBackfillApprovalGroupRulesUsersGroupId < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillApprovalGroupRulesUsersGroupId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :approval_group_rules_users,
      :id,
      :group_id,
      :approval_group_rules,
      :group_id,
      :approval_group_rule_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :approval_group_rules_users,
      :id,
      [
        :group_id,
        :approval_group_rules,
        :group_id,
        :approval_group_rule_id
      ]
    )
  end
end
