# frozen_string_literal: true

class QueueBackfillUpstreamPipelinePartitionIdOnPCiBuilds < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "BackfillUpstreamPipelinePartitionIdOnPCiBuilds"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1_000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :p_ci_builds,
      :upstream_pipeline_id,
      batch_class_name: 'LooseIndexScanBatchingStrategy',
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :p_ci_builds, :upstream_pipeline_id, [])
  end
end
