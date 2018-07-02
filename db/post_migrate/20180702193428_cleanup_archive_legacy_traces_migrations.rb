class CleanupArchiveLegacyTracesMigrations < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BACKGROUND_MIGRATION_CLASS = 'ArchiveLegacyTraces'

  disable_ddl_transaction!

  def up
    Gitlab::BackgroundMigration.steal(BACKGROUND_MIGRATION_CLASS)
  end

  def down
    # noop
  end
end
