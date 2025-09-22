# frozen_string_literal: true

class QueueBackfillTagNameOnCiRunnerTaggings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.5'

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = 'BackfillTagNameOnCiRunnerTaggings'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 1_000

  def up
    queue_batched_background_migration(
      MIGRATION,
      :ci_runner_taggings,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :ci_runner_taggings, :id, [])
  end
end
