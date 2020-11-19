# frozen_string_literal: true

class SchedulePopulateHasVulnerabilities < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 1_000
  DELAY_INTERVAL = 2.minutes
  MIGRATION_CLASS = 'PopulateHasVulnerabilities'

  disable_ddl_transaction!

  def up
    Gitlab::BackgroundMigration::PopulateHasVulnerabilities::Vulnerability.distinct.each_batch(of: BATCH_SIZE, column: :project_id) do |batch, index|
      project_ids = batch.pluck(:project_id)

      migrate_in(index * DELAY_INTERVAL, MIGRATION_CLASS, project_ids)
    end
  end

  def down
    # no-op
  end
end
