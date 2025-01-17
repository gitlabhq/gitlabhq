# frozen_string_literal: true

class QueueRecalculateShardingKeyIdForOrphanedProjectRunnerTaggings < Gitlab::Database::Migration[2.2]
  milestone '17.8'

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "RecalculateShardingKeyIdForOrphanedProjectRunnerTaggings"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 5000
  SUB_BATCH_SIZE = 500

  def up
    queue_batched_background_migration(
      MIGRATION,
      :ci_runner_taggings,
      :runner_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      batch_class_name: 'LooseIndexScanBatchingStrategy', # Override the default batching strategy
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :ci_runner_taggings, :runner_id, [])
  end
end
