# frozen_string_literal: true

class ScheduleFixingSecurityScanStatuses < Gitlab::Database::Migration[2.0]
  MIGRATION = 'FixSecurityScanStatuses'
  TABLE_NAME = :security_scans
  BATCH_COLUMN = :id
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10_000
  MAX_BATCH_SIZE = 50_000
  SUB_BATCH_SIZE = 100

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class SecurityScan < MigrationRecord
    def self.start_migration_from
      sort_order = Arel::Nodes::SqlLiteral.new("date(timezone('UTC'::text, created_at)) ASC, id ASC")

      where("date(timezone('UTC'::text, created_at)) > ?", 90.days.ago).order(sort_order).first&.id
    end
  end

  def up
    # Only the SaaS application is affected
    return unless Gitlab.dev_or_test_env? || Gitlab.com?

    batch_min_value = SecurityScan.start_migration_from

    return unless batch_min_value # It is possible that some users don't have corrupted records

    queue_batched_background_migration(
      MIGRATION,
      TABLE_NAME,
      BATCH_COLUMN,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      batch_min_value: batch_min_value
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      TABLE_NAME,
      BATCH_COLUMN,
      []
    )
  end
end
