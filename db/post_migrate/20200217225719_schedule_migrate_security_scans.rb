# frozen_string_literal: true

class ScheduleMigrateSecurityScans < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INTERVAL = 2.minutes.to_i
  BATCH_SIZE = 10_000
  MIGRATION = 'MigrateSecurityScans'

  disable_ddl_transaction!

  class JobArtifact < ActiveRecord::Base
    include ::EachBatch

    self.table_name = 'ci_job_artifacts'

    scope :security_reports, -> { where('file_type BETWEEN 5 and 8') }
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(JobArtifact.security_reports,
                                                          MIGRATION,
                                                          INTERVAL,
                                                          batch_size: BATCH_SIZE)
  end

  def down
    # intentionally blank
  end
end
