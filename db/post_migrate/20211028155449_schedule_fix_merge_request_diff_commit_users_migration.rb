# frozen_string_literal: true

class ScheduleFixMergeRequestDiffCommitUsersMigration < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  MIGRATION_CLASS = 'FixMergeRequestDiffCommitUsers'

  class Project < ApplicationRecord
    include EachBatch

    self.table_name = 'projects'
  end

  def up
    # This is the day on which we merged
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63669. Since the
    # deploy of this MR we may have imported projects using the old format, but
    # after their merge_request_diff_id range had been migrated by Sidekiq. As a
    # result, there may be rows without a committer_id or commit_author_id
    # field.
    date = '2021-07-07 00:00:00'

    transaction do
      Project.each_batch(of: 10_000) do |batch|
        time = Time.now.utc
        rows = batch
          .where('created_at >= ?', date)
          .where(import_type: 'gitlab_project')
          .pluck(:id)
          .map do |id|
            Gitlab::Database::BackgroundMigrationJob.new(
              class_name: MIGRATION_CLASS,
              arguments: [id],
              created_at: time,
              updated_at: time
            )
          end

        Gitlab::Database::BackgroundMigrationJob
          .bulk_insert!(rows, validate: false)
      end
    end

    job = Gitlab::Database::BackgroundMigrationJob
      .for_migration_class(MIGRATION_CLASS)
      .pending
      .first

    migrate_in(2.minutes, MIGRATION_CLASS, job.arguments) if job
  end

  def down
    # no-op
  end
end
