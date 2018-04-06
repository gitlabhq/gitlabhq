class ScheduleSetConfidentialNoteEventsOnWebhooks < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 1_000
  INTERVAL = 5.minutes

  disable_ddl_transaction!

  def up
    migration = Gitlab::BackgroundMigration::SetConfidentialNoteEventsOnWebhooks
    migration_name = migration.to_s.demodulize
    relation = migration::WebHook.hooks_to_update

    queue_background_migration_jobs_by_range_at_intervals(relation,
                                                          migration_name,
                                                          INTERVAL,
                                                          batch_size: BATCH_SIZE)
  end

  def down
  end
end
