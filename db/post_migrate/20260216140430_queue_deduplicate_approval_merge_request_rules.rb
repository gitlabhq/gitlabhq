# frozen_string_literal: true

class QueueDeduplicateApprovalMergeRequestRules < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "DeduplicateApprovalMergeRequestRules"
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 500

  def up
    queue_batched_background_migration(
      MIGRATION,
      :approval_merge_request_rules,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :approval_merge_request_rules, :id, [])
  end
end
