# frozen_string_literal: true

class BackfillPartitionedProjectDailyStatistics < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.5'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  START_DATE = 3.months.ago.beginning_of_month
  MAX_ATTEMPTS = 40
  MIGRATION = 'BackfillPartitionedProjectDailyStatistics'

  def up
    min_id = find_valid_min_id

    if min_id.nil?
      say "Migration skipped: No valid records found to start backfilling"
      return
    end

    enqueue_partitioning_data_migration 'project_daily_statistics', MIGRATION, batch_min_value: min_id
  end

  def down
    cleanup_partitioning_data_migration 'project_daily_statistics', MIGRATION
  end

  private

  def find_valid_min_id
    current_date = self.class::START_DATE
    min_id = nil
    attempts = 0
    max_attempts = self.class::MAX_ATTEMPTS

    say "Starting search from #{current_date}"

    while min_id.nil? && attempts < max_attempts
      attempts += 1
      min_id = connection.select_value(
        "SELECT MIN(id) FROM project_daily_statistics WHERE date = '#{current_date}'"
      )

      if min_id.nil?
        say "Attempt #{attempts}: No records found for #{current_date}, trying next day"
        current_date += 1.day
      else
        say "Success! Found min_id #{min_id} for date #{current_date} after #{attempts} attempts"
      end
    end

    min_id
  end
end
