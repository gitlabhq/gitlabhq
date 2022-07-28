# frozen_string_literal: true

class RescheduleBackfillImportedIssueSearchData < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'BackfillImportedIssueSearchData'
  DELAY_INTERVAL = 120.seconds
  BATCH_SIZE = 50_000
  SUB_BATCH_SIZE = 1_000

  def up
    # remove the original migration
    delete_batched_background_migration(MIGRATION, :issues, :id, [])

    # reschedule the migration
    queue_batched_background_migration(
      MIGRATION,
      :issues,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_min_value: min_value,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :issues, :id, [])
  end

  private

  def min_value
    start_value = Gitlab::Database::BackgroundMigration::BatchedMigration.find_by(
      job_class_name: "BackfillIssueSearchData"
    )&.max_value

    return BATCH_MIN_VALUE unless start_value

    max_value = Issue.maximum(:id)

    return BATCH_MIN_VALUE unless max_value

    # Just in case the issue's max ID is now lower than the history in the table
    [start_value, max_value].min
  end
end
