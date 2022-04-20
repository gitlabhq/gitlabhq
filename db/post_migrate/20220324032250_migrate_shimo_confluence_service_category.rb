# frozen_string_literal: true

class MigrateShimoConfluenceServiceCategory < Gitlab::Database::Migration[1.0]
  MIGRATION = 'MigrateShimoConfluenceIntegrationCategory'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10_000

  disable_ddl_transaction!

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      define_batchable_model('integrations').where(type_new: %w[Integrations::Confluence Integrations::Shimo]),
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      track_jobs: true)
  end

  def down
  end
end
