# frozen_string_literal: true

class QueueCreateComplianceStandardsAdherence < Gitlab::Database::Migration[2.1]
  MIGRATION = "CreateComplianceStandardsAdherence"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 500

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    return unless Gitlab.ee? # Standards adherence is available only in EE version

    queue_batched_background_migration(
      MIGRATION,
      :projects,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :projects, :id, [])
  end
end
