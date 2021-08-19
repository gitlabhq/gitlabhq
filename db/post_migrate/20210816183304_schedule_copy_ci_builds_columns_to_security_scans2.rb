# frozen_string_literal: true

class ScheduleCopyCiBuildsColumnsToSecurityScans2 < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  INTERVAL = 2.minutes.to_i
  BATCH_SIZE = 5_000
  MIGRATION = 'CopyCiBuildsColumnsToSecurityScans'

  disable_ddl_transaction!

  class SecurityScan < ActiveRecord::Base
    include EachBatch

    self.table_name = 'security_scans'
  end

  def up
    SecurityScan.reset_column_information

    delete_job_tracking(MIGRATION, status: %w[pending succeeded])

    queue_background_migration_jobs_by_range_at_intervals(
      SecurityScan,
      MIGRATION,
      INTERVAL,
      batch_size: BATCH_SIZE,
      track_jobs: true
    )
  end

  def down
    # noop
  end
end
