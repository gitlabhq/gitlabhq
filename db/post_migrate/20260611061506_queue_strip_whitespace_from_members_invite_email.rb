# frozen_string_literal: true

class QueueStripWhitespaceFromMembersInviteEmail < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "StripWhitespaceFromMembersInviteEmail"
  DELAY_INTERVAL = 10.seconds
  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 1_000

  def up
    queue_batched_background_migration(
      MIGRATION,
      :members,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :members, :id, [])
  end
end
