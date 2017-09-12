class CleanStagesStatusesMigration < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    Gitlab::BackgroundMigration.steal('MigrateStageStatus')
  end

  def down
    # noop
  end
end
