class CleanStageIdReferenceMigration < ActiveRecord::Migration[4.2]
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
