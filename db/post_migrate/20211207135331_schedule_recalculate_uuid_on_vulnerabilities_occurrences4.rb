# frozen_string_literal: true

class ScheduleRecalculateUuidOnVulnerabilitiesOccurrences4 < Gitlab::Database::Migration[1.0]
  MIGRATION = 'RecalculateVulnerabilitiesOccurrencesUuid'
  DELAY_INTERVAL = 2.minutes.to_i
  BATCH_SIZE = 2_500

  disable_ddl_transaction!

  def up
    # Make sure the migration removing Findings with attributes for which UUID would be identical
    # has finished
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/74008
    Gitlab::BackgroundMigration.steal('RemoveOccurrencePipelinesAndDuplicateVulnerabilitiesFindings')

    queue_background_migration_jobs_by_range_at_intervals(
      define_batchable_model('vulnerability_occurrences'),
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      track_jobs: true
    )
  end

  def down
    # no-op
  end
end
