class MigrateStageIdReferenceInBackground < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 10000
  MIGRATION = 'MigrateBuildStageIdReference'.freeze

  disable_ddl_transaction!

  class Build < ActiveRecord::Base
    self.table_name = 'ci_builds'
  end

  def up
    Build.where(stage_id: nil)
      .find_in_batches(batch_size: BATCH_SIZE)
      .with_index do |builds, batch|
        builds.each do |build|
          schedule = (batch - 1) * 5.minutes
          BackgroundMigrationWorker.perform_at(schedule, MIGRATION, [build.id])
        end
      end
  end

  def down
    # noop
  end
end
