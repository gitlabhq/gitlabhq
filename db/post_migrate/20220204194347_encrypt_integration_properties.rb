# frozen_string_literal: true

class EncryptIntegrationProperties < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!
  MIGRATION = 'EncryptIntegrationProperties'
  BATCH_SIZE = 1_000
  INTERVAL = 2.minutes.to_i

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      define_batchable_model('integrations').all,
      MIGRATION,
      INTERVAL,
      track_jobs: true,
      batch_size: BATCH_SIZE
    )
  end

  def down
    # this migration is not reversible
  end
end
