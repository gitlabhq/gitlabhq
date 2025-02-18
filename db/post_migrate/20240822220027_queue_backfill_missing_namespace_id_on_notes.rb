# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/database/batched_background_migrations.html
# for more information on when/how to queue batched background migrations

# Update below commented lines with appropriate values.

class QueueBackfillMissingNamespaceIdOnNotes < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillMissingNamespaceIdOnNotes"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100
  GITLAB_OPTIMIZED_BATCH_SIZE = 75_000
  GITLAB_OPTIMIZED_SUB_BATCH_SIZE = 250

  def up
    queue_batched_background_migration(
      MIGRATION,
      :notes,
      :id,
      job_interval: DELAY_INTERVAL,
      **batch_sizes
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :notes, :id, [])
  end

  private

  def batch_sizes
    if Gitlab.com_except_jh?
      {
        batch_size: GITLAB_OPTIMIZED_BATCH_SIZE,
        sub_batch_size: GITLAB_OPTIMIZED_SUB_BATCH_SIZE
      }
    else
      {
        batch_size: BATCH_SIZE,
        sub_batch_size: SUB_BATCH_SIZE
      }
    end
  end
end
