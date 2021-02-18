# frozen_string_literal: true

class ScheduleRemoveDuplicateVulnerabilitiesFindings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  INDEX_NAME = 'tmp_idx_deduplicate_vulnerability_occurrences'

  MIGRATION = 'RemoveDuplicateVulnerabilitiesFindings'
  DELAY_INTERVAL = 2.minutes.to_i
  BATCH_SIZE = 5_000

  disable_ddl_transaction!

  class VulnerabilitiesFinding < ActiveRecord::Base
    include ::EachBatch
    self.table_name = "vulnerability_occurrences"
  end

  def up
    add_concurrent_index :vulnerability_occurrences,
      %i[project_id report_type location_fingerprint primary_identifier_id id],
      name: INDEX_NAME

    say "Scheduling #{MIGRATION} jobs"
    queue_background_migration_jobs_by_range_at_intervals(
      VulnerabilitiesFinding,
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE
    )
  end

  def down
    remove_concurrent_index_by_name(:vulnerability_occurrences, INDEX_NAME)
  end
end
