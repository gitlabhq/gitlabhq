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
    index = 1

    Build.where(stage_id: nil).in_batches(of: BATCH_SIZE) do |relation|
      jobs = relation.pluck(:id).map { |id| [MIGRATION, [id]] }
      schedule = index * 5.minutes
      index += 1

      BackgroundMigrationWorker.perform_bulk_in(schedule, jobs)
    end
  end

  def down
    # noop
  end
end
