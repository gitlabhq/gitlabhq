# frozen_string_literal: true

class QueueBackfillDoraDailyMetricsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillDoraDailyMetricsProjectId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 5000
  SUB_BATCH_SIZE = 500

  def up
    queue_batched_background_migration(
      MIGRATION,
      :dora_daily_metrics,
      :id,
      :project_id,
      :environments,
      :project_id,
      :environment_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :dora_daily_metrics,
      :id,
      [
        :project_id,
        :environments,
        :project_id,
        :environment_id
      ]
    )
  end
end
