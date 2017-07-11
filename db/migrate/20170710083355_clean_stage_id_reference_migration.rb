require Rails.root.join('db', 'post_migrate', '20170628080858_migrate_stage_id_reference_in_background')

class CleanStageIdReferenceMigration < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  ##
  # `MigrateStageIdReferenceInBackground` background migration cleanup.
  #
  def up
    Gitlab::BackgroundMigration
      .steal(MigrateStageIdReferenceInBackground::MIGRATION)
  end

  def down
    # noop
  end
end
