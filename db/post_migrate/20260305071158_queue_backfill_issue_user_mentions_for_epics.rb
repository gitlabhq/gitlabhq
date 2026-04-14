# frozen_string_literal: true

class QueueBackfillIssueUserMentionsForEpics < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  disable_ddl_transaction!

  MIGRATION = "BackfillIssueUserMentionsForEpics"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 1_000

  def up
    queue_batched_background_migration(
      MIGRATION,
      :epic_user_mentions,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :epic_user_mentions, :id, [])
  end
end
