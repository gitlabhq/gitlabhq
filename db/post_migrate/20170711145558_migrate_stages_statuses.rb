class MigrateStagesStatuses < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  BATCH_SIZE = 10000
  RANGE_SIZE = 100
  MIGRATION = 'MigrateStageStatus'.freeze

  class Stage < ActiveRecord::Base
    self.table_name = 'ci_stages'
    include ::EachBatch
  end

  def up
    Stage.where(status: nil).each_batch(of: BATCH_SIZE) do |relation, index|
      relation.each_batch(of: RANGE_SIZE) do |batch|
        range = batch.pluck('MIN(id)', 'MAX(id)').first
        delay = index * 5.minutes

        BackgroundMigrationWorker.perform_in(delay, MIGRATION, range)
      end
    end
  end

  def down
    disable_statement_timeout

    update_column_in_batches(:ci_stages, :status, nil)
  end
end
