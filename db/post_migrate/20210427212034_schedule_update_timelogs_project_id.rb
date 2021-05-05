# frozen_string_literal: true

class ScheduleUpdateTimelogsProjectId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 50_000
  DELAY_INTERVAL = 2.minutes
  MIGRATION = 'UpdateTimelogsProjectId'

  disable_ddl_transaction!

  class Timelog < ActiveRecord::Base
    include EachBatch

    self.table_name = 'timelogs'
    self.inheritance_column = :_type_disabled
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      Timelog.all,
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE
    )
  end

  def down
    # no-op
  end
end
