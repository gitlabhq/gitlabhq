# frozen_string_literal: true

class SchedulePopulateMissingDismissalInformationForVulnerabilities < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 1_000
  DELAY_INTERVAL = 3.minutes.to_i
  MIGRATION_CLASS = 'PopulateMissingVulnerabilityDismissalInformation'

  disable_ddl_transaction!

  def up
    ::Gitlab::BackgroundMigration::PopulateMissingVulnerabilityDismissalInformation::Vulnerability.broken.each_batch(of: BATCH_SIZE) do |batch, index|
      vulnerability_ids = batch.pluck(:id)
      migrate_in(index * DELAY_INTERVAL, MIGRATION_CLASS, vulnerability_ids)
    end
  end

  def down
    # no-op
  end
end
