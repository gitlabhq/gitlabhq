class MigrateStagesStatuses < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  BATCH_SIZE = 10000
  MIGRATION = 'MigrateStageStatus'.freeze

  class Stage < ActiveRecord::Base
    self.table_name = 'ci_stages'
  end

  def up
    index = 1

    Stage.where(status: nil).in_batches(of: BATCH_SIZE) do |relation|
      jobs = relation.pluck(:id).map { |id| [MIGRATION, [id]] }
      schedule = index * 5.minutes
      index += 1

      BackgroundMigrationWorker.perform_bulk_in(schedule, jobs)
    end
  end

  def down
    disable_statement_timeout

    execute <<-SQL.strip_heredoc
      UPDATE ci_stages SET status = null
    SQL
  end
end
