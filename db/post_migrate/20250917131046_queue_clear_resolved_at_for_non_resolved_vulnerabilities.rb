# frozen_string_literal: true

class QueueClearResolvedAtForNonResolvedVulnerabilities < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  MIGRATION = "ClearResolvedAtForNonResolvedVulnerabilities"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 100

  def up
    delete_batched_background_migration(MIGRATION, :vulnerabilities, :id, [])

    queue_batched_background_migration(
      MIGRATION,
      :vulnerabilities,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      job_interval: DELAY_INTERVAL
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :vulnerabilities, :id, [])
  end
end
