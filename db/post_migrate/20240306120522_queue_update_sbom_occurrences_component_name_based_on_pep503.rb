# frozen_string_literal: true

class QueueUpdateSbomOccurrencesComponentNameBasedOnPep503 < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  MIGRATION = "UpdateSbomOccurrencesComponentNameBasedOnPep503"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 2000
  SUB_BATCH_SIZE = 200

  def up
    queue_batched_background_migration(
      MIGRATION,
      :sbom_occurrences,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :sbom_occurrences, :id, [])
  end
end
