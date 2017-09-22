class CleanStagesStatusesMigration < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class Stage < ActiveRecord::Base
    include ::EachBatch
    self.table_name = 'ci_stages'
  end

  def up
    Gitlab::BackgroundMigration.steal('MigrateStageStatus')

    Stage.where('status IS NULL').each_batch(of: 50) do |batch|
      range = batch.pluck('MIN(id)', 'MAX(id)').first

      Gitlab::BackgroundMigration::MigrateStageStatus.new.perform(*range)
    end
  end

  def down
    # noop
  end
end
