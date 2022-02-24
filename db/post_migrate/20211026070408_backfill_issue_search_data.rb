# frozen_string_literal: true

class BackfillIssueSearchData < Gitlab::Database::Migration[1.0]
  MIGRATION = 'BackfillIssueSearchData'

  def up
    queue_batched_background_migration(
      MIGRATION,
      :issues,
      :id,
      batch_size: 100_000,
      sub_batch_size: 1_000,
      job_interval: 5.minutes
    )
  end

  def down
    Gitlab::Database::BackgroundMigration::BatchedMigration
      .for_configuration(MIGRATION, :issues, :id, [])
      .delete_all
  end
end
