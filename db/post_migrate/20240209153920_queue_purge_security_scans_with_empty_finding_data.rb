# frozen_string_literal: true

class QueuePurgeSecurityScansWithEmptyFindingData < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  MIGRATION = "PurgeSecurityScansWithEmptyFindingData"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  class SecurityScan < MigrationRecord
    self.table_name = 'security_scans'

    has_many :findings,
      foreign_key: :scan_id,
      class_name: 'QueuePurgeSecurityScansWithEmptyFindingData::SecurityFinding'

    scope :succeeded, -> { where(status: 1) }
  end

  class SecurityFinding < MigrationRecord
    self.table_name = 'security_findings'
  end

  def up
    return if Gitlab.com? || !Gitlab.ee?

    first_succeeded_scan = SecurityScan.succeeded.first

    return unless first_succeeded_scan

    first_finding = first_succeeded_scan.findings.first

    return if first_finding&.finding_data.present?

    queue_batched_background_migration(
      MIGRATION,
      :security_scans,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      batch_min_value: first_succeeded_scan.id
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :security_scans, :id, [])
  end
end
