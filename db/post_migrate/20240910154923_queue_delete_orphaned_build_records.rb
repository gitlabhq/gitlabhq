# frozen_string_literal: true

class QueueDeleteOrphanedBuildRecords < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = 'DeleteOrphanedBuildRecords'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 5000
  SUB_BATCH_SIZE = 1000
  MIN_PIPELINE_ID = 1104078878

  def up
    queue_batched_background_migration(
      MIGRATION,
      :p_ci_builds,
      :commit_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      batch_class_name: 'LooseIndexScanBatchingStrategy',
      sub_batch_size: SUB_BATCH_SIZE,
      batch_min_value: batch_min_value
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :p_ci_builds, :commit_id, [])
  end

  def batch_min_value
    if Gitlab.com_except_jh?
      MIN_PIPELINE_ID
    else
      1
    end
  end
end
