# frozen_string_literal: true

class QueueBackfillDastProfilesPipelinesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  MIGRATION = "BackfillDastProfilesPipelinesProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :dast_profiles_pipelines,
      :ci_pipeline_id,
      :project_id,
      :dast_profiles,
      :project_id,
      :dast_profile_id,
      job_interval: DELAY_INTERVAL,
      batch_class_name: 'LooseIndexScanBatchingStrategy',
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :dast_profiles_pipelines,
      :ci_pipeline_id,
      [
        :project_id,
        :dast_profiles,
        :project_id,
        :dast_profile_id
      ]
    )
  end
end
