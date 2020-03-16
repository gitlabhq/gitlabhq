# frozen_string_literal: true

class ScheduleRecalculateProjectAuthorizationsSecondRun < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  MIGRATION = 'RecalculateProjectAuthorizationsWithMinMaxUserId'
  BATCH_SIZE = 2_500
  DELAY_INTERVAL = 2.minutes.to_i

  disable_ddl_transaction!

  class User < ActiveRecord::Base
    include ::EachBatch

    self.table_name = 'users'
  end

  def up
    say "Scheduling #{MIGRATION} jobs"

    User.each_batch(of: BATCH_SIZE) do |batch, index|
      delay = index * DELAY_INTERVAL
      range = batch.pluck('MIN(id)', 'MAX(id)').first
      BackgroundMigrationWorker.perform_in(delay, MIGRATION, range)
    end
  end

  def down
  end
end
