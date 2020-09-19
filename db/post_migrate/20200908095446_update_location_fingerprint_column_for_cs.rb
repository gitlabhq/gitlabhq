# frozen_string_literal: true

class UpdateLocationFingerprintColumnForCs < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  BATCH_SIZE = 1_000
  INTERVAL = 2.minutes

  # 883_152 records
  def up
    return unless Gitlab.ee?

    migration = Gitlab::BackgroundMigration::UpdateLocationFingerprintForContainerScanningFindings
    migration_name = migration.to_s.demodulize
    relation = migration::Finding.container_scanning
    queue_background_migration_jobs_by_range_at_intervals(relation,
                                                          migration_name,
                                                          INTERVAL,
                                                          batch_size: BATCH_SIZE)
  end

  def down
    # no-op
    # intentionally blank
  end
end
