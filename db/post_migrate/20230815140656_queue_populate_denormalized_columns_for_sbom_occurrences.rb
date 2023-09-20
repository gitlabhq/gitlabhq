# frozen_string_literal: true

class QueuePopulateDenormalizedColumnsForSbomOccurrences < Gitlab::Database::Migration[2.1]
  MIGRATION = "PopulateDenormalizedColumnsForSbomOccurrences"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 5_000
  SUB_BATCH_SIZE = 100

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

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
