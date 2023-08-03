# frozen_string_literal: true

class BackfillProjectStatisticsStorageSizeWithoutPipelineArtifactsSize < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillProjectStatisticsStorageSizeWithoutPipelineArtifactsSizeJob"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 500
  SUB_BATCH_SIZE = 100

  def up
    return unless Gitlab.dev_or_test_env? || Gitlab.org_or_com?

    queue_batched_background_migration(
      MIGRATION,
      :project_statistics,
      :project_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    return unless Gitlab.dev_or_test_env? || Gitlab.org_or_com?

    delete_batched_background_migration(MIGRATION, :project_statistics, :project_id, [])
  end
end
