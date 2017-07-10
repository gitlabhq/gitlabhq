class MigrateStagesStatuses < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  BATCH_SIZE = 10000
  RANGE_SIZE = 1000
  MIGRATION = 'MigrateStageStatus'.freeze

  class Stage < ActiveRecord::Base
    self.table_name = 'ci_stages'
    include ::EachBatch
  end

  def up
    Stage.where(status: nil).each_batch(of: BATCH_SIZE) do |relation, index|
      relation.each_batch(of: RANGE_SIZE) do |batch|
        range = relation.pluck('MIN(id)', 'MAX(id)').first
        schedule = index * 5.minutes

        BackgroundMigrationWorker.perform_in(schedule, MIGRATION, range)
      end
    end
  end

  def down
    disable_statement_timeout

    execute <<-SQL.strip_heredoc
      UPDATE ci_stages SET status = null
    SQL
  end
end
