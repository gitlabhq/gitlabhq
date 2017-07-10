class MigrateStageIdReferenceInBackground < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 10000
  RANGE_SIZE = 1000
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
    Build.where(stage_id: nil).each_batch(of: BATCH_SIZE) do |relation, index|
      relation.each_batch(of: RANGE_SIZE) do |relation|
        range = relation.pluck('MIN(id)', 'MAX(id)').first

        BackgroundMigrationWorker
          .perform_in(index * 2.minutes, MIGRATION, range)
      end
    end
  end

  def down
    # noop
  end
end
