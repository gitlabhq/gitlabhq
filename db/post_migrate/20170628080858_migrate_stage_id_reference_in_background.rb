class MigrateStageIdReferenceInBackground < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 10000
  MIGRATION = 'MigrateBuildStageIdReference'.freeze

  disable_ddl_transaction!

  class Build < ActiveRecord::Base
    self.table_name = 'ci_builds'
    include ::EachBatch
  end

  ##
  # It will take around 3 days to process 20M ci_builds.
  #
  def up
    Build.all.each_batch(of: BATCH_SIZE) do |relation, index|
      range = relation.pluck('MIN(id)', 'MAX(id)').first
      schedule = index * 2.minutes

      BackgroundMigrationWorker.perform_in(schedule, MIGRATION, range)
    end
  end

  def down
    # noop
  end
end
