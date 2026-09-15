# frozen_string_literal: true

class DeleteMigrateProjectAuthorizationsBatchedJobs < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  disable_ddl_transaction!

  TABLE_NAME = :project_authorizations
  MIGRATION = "MigrateProjectAuthorizations"
  BATCH_SIZE = 1_000

  def up
    # Deleting the previous run in RequeueMigrateProjectAuthorizations cascades
    # to all its job and transition log rows in one statement, which times out
    # on GitLab.com. Delete the job rows in batches first to keep it small.
    Gitlab::Database::BackgroundMigration::BatchedMigration.reset_column_information

    Gitlab::Database::BackgroundMigration::BatchedMigration
      .for_configuration(:gitlab_main, MIGRATION, TABLE_NAME, :user_id, [], include_compatible: true)
      .each do |migration|
        Gitlab::Database::BackgroundMigration::BatchedJob
          .where(batched_background_migration_id: migration.id)
          .each_batch(of: BATCH_SIZE) { |batch| batch.delete_all }
      end
  end

  def down
    # no-op because the job rows of the finished previous run cannot be
    # restored. The requeued batched background migration recreates them.
  end
end
