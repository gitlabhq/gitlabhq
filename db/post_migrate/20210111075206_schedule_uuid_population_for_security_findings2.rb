# frozen_string_literal: true

# This replaces the previous post-deployment migration 20210111075105_schedule_uuid_population_for_security_findings.rb,
# we have to run this again due to a bug in how we were receiving the arguments in the background migration.
class ScheduleUuidPopulationForSecurityFindings2 < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION_CLASS = 'PopulateUuidsForSecurityFindings'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 25

  disable_ddl_transaction!

  def up
    ::Gitlab::BackgroundMigration.steal(MIGRATION_CLASS) do |job|
      job.delete

      false
    end

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
