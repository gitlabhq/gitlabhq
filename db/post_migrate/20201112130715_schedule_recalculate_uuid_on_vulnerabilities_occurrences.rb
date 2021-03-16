# frozen_string_literal: true

class ScheduleRecalculateUuidOnVulnerabilitiesOccurrences < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  MIGRATION = 'RecalculateVulnerabilitiesOccurrencesUuid'
  DELAY_INTERVAL = 2.minutes.to_i
  BATCH_SIZE = 2_500

  disable_ddl_transaction!

  class VulnerabilitiesFinding < ActiveRecord::Base
    include ::EachBatch

    self.table_name = "vulnerability_occurrences"
  end

  def up
    # Make sure that RemoveDuplicateVulnerabilitiesFindings has finished running
    # so that we don't run into duplicate UUID issues
    Gitlab::BackgroundMigration.steal('RemoveDuplicateVulnerabilitiesFindings')

    say "Scheduling #{MIGRATION} jobs"
    queue_background_migration_jobs_by_range_at_intervals(
      VulnerabilitiesFinding,
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE
    )
  end

  def down
    # no-op
  end
end
