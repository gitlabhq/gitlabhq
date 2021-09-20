# frozen_string_literal: true

class SliceMergeRequestDiffCommitMigrations < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  BATCH_SIZE = 5_000
  MIGRATION_CLASS = 'MigrateMergeRequestDiffCommitUsers'
  STEAL_MIGRATION_CLASS = 'StealMigrateMergeRequestDiffCommitUsers'

  def up
    old_jobs = Gitlab::Database::BackgroundMigrationJob
      .for_migration_class(MIGRATION_CLASS)
      .pending
      .to_a

    return if old_jobs.empty?

    transaction do
      # This ensures we stop processing the old ranges, as the background
      # migrations skip already processed jobs.
      Gitlab::Database::BackgroundMigrationJob
        .for_migration_class(MIGRATION_CLASS)
        .pending
        .update_all(status: :succeeded)

      rows = []

      old_jobs.each do |job|
        min, max = job.arguments

        while min < max
          rows << {
            class_name: MIGRATION_CLASS,
            arguments: [min, min + BATCH_SIZE],
            created_at: Time.now.utc,
            updated_at: Time.now.utc
          }

          min += BATCH_SIZE
        end
      end

      Gitlab::Database::BackgroundMigrationJob.insert_all!(rows)
    end

    job = Gitlab::Database::BackgroundMigrationJob
      .for_migration_class(MIGRATION_CLASS)
      .pending
      .first

    migrate_in(1.hour, STEAL_MIGRATION_CLASS, job.arguments)
  end

  def down
    # no-op
  end
end
