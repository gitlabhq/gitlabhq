# frozen_string_literal: true

class ScheduleMigrateU2fWebauthn < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  INTERVAL = 2.minutes.to_i
  DOWNTIME = false
  MIGRATION = 'MigrateU2fWebauthn'
  BATCH_SIZE = 1_000

  disable_ddl_transaction!

  class U2fRegistration < ActiveRecord::Base
    include EachBatch

    self.table_name = 'u2f_registrations'
  end

  def up
    say "Scheduling #{MIGRATION} background migration jobs"

    queue_background_migration_jobs_by_range_at_intervals(U2fRegistration, MIGRATION, INTERVAL, batch_size: BATCH_SIZE)
  end

  def down
    # no-op
    # There is no real way back here, because
    # a) The U2fMigrator of webauthn_ruby gem only works in one way
    # b) This migration only pushes jobs to Sidekiq
  end
end
