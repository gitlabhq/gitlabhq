# frozen_string_literal: true

class RescheduleExtractProjectTopicsIntoSeparateTable2 < Gitlab::Database::Migration[1.0]
  MIGRATION = 'ExtractProjectTopicsIntoSeparateTable'
  DELAY_INTERVAL = 4.minutes

  disable_ddl_transaction!

  def up
    requeue_background_migration_jobs_by_range_at_intervals(MIGRATION, DELAY_INTERVAL)
  end

  def down
    # no-op
  end
end
