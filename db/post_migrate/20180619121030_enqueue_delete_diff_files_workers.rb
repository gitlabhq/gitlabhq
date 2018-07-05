class EnqueueDeleteDiffFilesWorkers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION = 'DeleteDiffFiles'.freeze

  disable_ddl_transaction!

  def up
    BackgroundMigrationWorker.perform_async(MIGRATION)
  end

  def down
    # no-op
  end
end
