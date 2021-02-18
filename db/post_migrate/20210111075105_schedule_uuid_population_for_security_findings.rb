# frozen_string_literal: true

class ScheduleUuidPopulationForSecurityFindings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION_CLASS = 'PopulateUuidsForSecurityFindings'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 25

  disable_ddl_transaction!

  def up
    Gitlab::BackgroundMigration::PopulateUuidsForSecurityFindings.security_findings.each_batch(column: :scan_id, of: BATCH_SIZE) do |batch, index|
      migrate_in(
        DELAY_INTERVAL * index,
        MIGRATION_CLASS,
        batch.pluck(:scan_id)
      )
    end
  end

  def down
    # no-op
  end
end
