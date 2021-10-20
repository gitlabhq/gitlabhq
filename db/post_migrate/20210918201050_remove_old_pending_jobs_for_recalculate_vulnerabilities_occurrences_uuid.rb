# frozen_string_literal: true

class RemoveOldPendingJobsForRecalculateVulnerabilitiesOccurrencesUuid < Gitlab::Database::Migration[1.0]
  MIGRATION_NAME = 'RecalculateVulnerabilitiesOccurrencesUuid'
  NEW_MIGRATION_START_DATE = DateTime.new(2021, 8, 18, 0, 0, 0)

  def up
    Gitlab::Database::BackgroundMigrationJob
      .for_migration_class(MIGRATION_NAME)
      .where('created_at < ?', NEW_MIGRATION_START_DATE)
      .where(status: :pending)
      .delete_all
  end

  def down
    # no-op
  end
end
