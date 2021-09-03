# frozen_string_literal: true

class BackfillProjectsWithCoverage < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  MIGRATION = 'BackfillProjectsWithCoverage'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 1_000

  disable_ddl_transaction!

  class CiDailyBuildGroupReportResult < ActiveRecord::Base
    include EachBatch

    self.table_name = 'ci_daily_build_group_report_results'
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      CiDailyBuildGroupReportResult,
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      other_job_arguments: [SUB_BATCH_SIZE]
    )
  end

  def down
    # noop
  end
end
