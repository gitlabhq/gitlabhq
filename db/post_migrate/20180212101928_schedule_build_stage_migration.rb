class ScheduleBuildStageMigration < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION = 'MigrateBuildStage'.freeze
  BATCH_SIZE = 500

  disable_ddl_transaction!

  class Build < ActiveRecord::Base
    include EachBatch
    self.table_name = 'ci_builds'
  end

  def up
    disable_statement_timeout

    add_concurrent_index(:ci_builds, :stage_id, where: 'stage_id IS NULL',
                                                name: 'tmp_stage_id_partial_null_index')

    Build.where('stage_id IS NULL').tap do |relation|
      queue_background_migration_jobs_by_range_at_intervals(relation,
                                                            MIGRATION,
                                                            5.minutes,
                                                            batch_size: BATCH_SIZE)
    end

    remove_concurrent_index_by_name(:ci_builds, 'tmp_stage_id_partial_null_index')
  end

  def down
    # noop
  end
end
