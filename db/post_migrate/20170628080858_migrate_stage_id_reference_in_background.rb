class MigrateStageIdReferenceInBackground < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 10000
  MIGRATION = 'MigrateBuildStageIdReference'.freeze

  disable_ddl_transaction!

  ##
  # It will take around 3 days to process 20M ci_builds.
  #
  def up
    opts = { scope: ->(table, query) { query.where(table[:stage_id].eq(nil)) },
             of: BATCH_SIZE }

    walk_table_in_batches(:ci_builds, **opts) do |index, start_id, stop_id|
      schedule = index * 2.minutes

      BackgroundMigrationWorker
        .perform_in(schedule, MIGRATION, [start_id, stop_id])
    end
  end

  def down
    # noop
  end
end
