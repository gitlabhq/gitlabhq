# frozen_string_literal: true

class SchedulePopulateResolvedOnDefaultBranchColumn < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 100
  DELAY_INTERVAL = 5.minutes.to_i
  MIGRATION_CLASS = 'PopulateResolvedOnDefaultBranchColumn'
  BASE_MODEL = EE::Gitlab::BackgroundMigration::PopulateResolvedOnDefaultBranchColumn::Vulnerability

  disable_ddl_transaction!

  def up
    return unless run_migration?

    BASE_MODEL.distinct.each_batch(of: BATCH_SIZE, column: :project_id) do |batch, index|
      project_ids = batch.pluck(:project_id)
      migrate_in(index * DELAY_INTERVAL, MIGRATION_CLASS, project_ids)
    end
  end

  def down; end

  private

  def run_migration?
    Gitlab.ee? && table_exists?(:projects) && table_exists?(:vulnerabilities)
  end
end
