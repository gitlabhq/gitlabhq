# frozen_string_literal: true

class RequeueBackfillDescriptionVersionsForEpics < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillDescriptionVersionsForEpics"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 250
  SUB_BATCH_SIZE = 50

  def up
    delete_batched_background_migration(MIGRATION, :epics, :id, [])

    queue_batched_background_migration(
      MIGRATION,
      :epics,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :epics, :id, [])
  end
end
