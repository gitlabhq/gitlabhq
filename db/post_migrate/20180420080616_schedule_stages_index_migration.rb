class ScheduleStagesIndexMigration < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION = 'MigrateStageIndex'.freeze
  BATCH_SIZE = 10000

  disable_ddl_transaction!

  class Stage < ActiveRecord::Base
    include EachBatch
    self.table_name = 'ci_stages'
  end

  def up
    disable_statement_timeout

    Stage.all.tap do |relation|
      queue_background_migration_jobs_by_range_at_intervals(relation,
                                                            MIGRATION,
                                                            5.minutes,
                                                            batch_size: BATCH_SIZE)
    end
  end

  def down
    # noop
  end
end
