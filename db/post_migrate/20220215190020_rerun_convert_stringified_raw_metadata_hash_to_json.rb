# frozen_string_literal: true

class RerunConvertStringifiedRawMetadataHashToJson < Gitlab::Database::Migration[1.0]
  MIGRATION_CLASS = Gitlab::BackgroundMigration::FixVulnerabilityOccurrencesWithHashesAsRawMetadata
  MODEL_CLASS = MIGRATION_CLASS::Finding
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 500

  disable_ddl_transaction!

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      MODEL_CLASS.by_api_report_types,
      MIGRATION_CLASS.name.demodulize,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      track_jobs: true
    )
  end

  def down
    # no-op

    # up fixes invalid data by updating columns in-place.
    # It is a backwards-compatible change, and reversing it in a downgrade would not be desirable.
  end
end
