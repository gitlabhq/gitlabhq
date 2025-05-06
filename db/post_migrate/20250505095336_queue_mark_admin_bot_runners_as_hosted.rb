# frozen_string_literal: true

class QueueMarkAdminBotRunnersAsHosted < Gitlab::Database::Migration[2.3]
  milestone '18.0'

  # Select the applicable gitlab schema for your batched background migration
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "MarkAdminBotRunnersAsHosted"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :ci_runners,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :ci_runners, :id, [])
  end
end
