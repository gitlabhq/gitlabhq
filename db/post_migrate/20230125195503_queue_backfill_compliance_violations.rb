# frozen_string_literal: true

class QueueBackfillComplianceViolations < Gitlab::Database::Migration[2.1]
  MIGRATION = 'BackfillComplianceViolations'
  INTERVAL = 2.minutes
  BATCH_SIZE = 10_000

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    queue_batched_background_migration(
      MIGRATION,
      :merge_requests_compliance_violations,
      :id,
      job_interval: INTERVAL,
      batch_size: BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :merge_requests_compliance_violations, :id, [])
  end
end
