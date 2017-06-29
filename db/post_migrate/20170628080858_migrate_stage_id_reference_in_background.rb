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
    Build.where(stage_id: nil).in_batches(of: BATCH_SIZE) do |relation, index|
      schedule = index * 5.minutes
      jobs = relation.pluck(:id).map { |id| [MIGRATION, [id]] }

      BackgroundMigrationWorker.perform_bulk_in(schedule, jobs)
    end
  end

  def down
    # noop
  end
end
