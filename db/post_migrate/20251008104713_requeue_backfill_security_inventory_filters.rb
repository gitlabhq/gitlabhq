# frozen_string_literal: true

class RequeueBackfillSecurityInventoryFilters < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  MIGRATION = "BackfillSecurityInventoryFilters"
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100
  DELAY_INTERVAL = 2.minutes

  def up
    delete_batched_background_migration(MIGRATION, :vulnerability_statistics, :project_id, [])

    queue_batched_background_migration(
      MIGRATION,
      :vulnerability_statistics,
      :project_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :vulnerability_statistics, :project_id, [])
  end
end
