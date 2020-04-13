# frozen_string_literal: true

class ScheduleRecalculateProjectAuthorizationsThirdRun < ActiveRecord::Migration[5.1]
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

    queue_background_migration_jobs_by_range_at_intervals(User, MIGRATION, DELAY_INTERVAL, batch_size: BATCH_SIZE)
  end

  def down
  end
end
