class ScheduleBuildStageMigration < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION = 'MigrateBuildStage'.freeze
  BATCH_SIZE = 800

  disable_ddl_transaction!

  class Build < ActiveRecord::Base
    include EachBatch
    self.table_name = 'ci_builds'
  end

  def up
    disable_statement_timeout

    Build.where('stage_id IS NULL').each_batch(of: BATCH_SIZE) do |builds, index|
      builds.pluck('MIN(id)', 'MAX(id)').first.tap do |range|
        BackgroundMigrationWorker.perform_in(index * 5.minutes, MIGRATION, range)
      end
    end
  end

  def down
    # noop
  end
end
