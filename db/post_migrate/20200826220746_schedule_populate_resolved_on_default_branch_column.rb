# frozen_string_literal: true

class SchedulePopulateResolvedOnDefaultBranchColumn < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 100
  DELAY_INTERVAL = 5.minutes.to_i
  MIGRATION_CLASS = 'PopulateResolvedOnDefaultBranchColumn'

  disable_ddl_transaction!

  def up
    return unless Gitlab.ee?

    EE::Gitlab::BackgroundMigration::PopulateResolvedOnDefaultBranchColumn::Vulnerability.distinct.each_batch(of: BATCH_SIZE, column: :project_id) do |batch, index|
      project_ids = batch.pluck(:project_id)
      migrate_in(index * DELAY_INTERVAL, MIGRATION_CLASS, project_ids)
    end
  end

  def down
    # no-op
    # This migration schedules background tasks to populate
    # `resolved_on_default_branch` column of `vulnerabilities`
    # table so there is no rollback operation needed for this.
  end
end
