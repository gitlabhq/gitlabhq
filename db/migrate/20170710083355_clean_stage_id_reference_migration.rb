class CleanStageIdReferenceMigration < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  ##
  # `MigrateStageIdReferenceInBackground` background migration cleanup.
  #
  def up
    Gitlab::BackgroundMigration.steal('MigrateBuildStageIdReference')
  end

  def down
    # noop
  end
end
