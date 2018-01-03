class ScheduleEpicIssuePositionsMigration < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  MIGRATION = 'SetEpicIssuesPositionValues'.freeze
  BATCH_SIZE = 100

  class Epic < ActiveRecord::Base
    self.table_name = 'epics'

    include EachBatch
  end

  def up
    Epic.select(:id).each_batch(of: BATCH_SIZE) do |batch, index|
      start_id, end_id = batch.pluck('MIN(id), MAX(id)').first

      BackgroundMigrationWorker.perform_in(index * 5.minutes, MIGRATION, [start_id, end_id])
    end
  end
end
