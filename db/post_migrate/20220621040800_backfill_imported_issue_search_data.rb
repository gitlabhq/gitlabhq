# frozen_string_literal: true

class BackfillImportedIssueSearchData < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'BackfillImportedIssueSearchData'
  DELAY_INTERVAL = 120.seconds

  def up
    min_value = Gitlab::Database::BackgroundMigration::BatchedMigration.find_by(
      job_class_name: "BackfillIssueSearchData"
    )&.max_value || BATCH_MIN_VALUE
    queue_batched_background_migration(
      MIGRATION,
      :issues,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_min_value: min_value
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :issues, :id, [])
  end
end
