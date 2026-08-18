# frozen_string_literal: true

class FinaliseBackfillCommitsToPartitioned < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = 'BackfillMergeRequestDiffCommitsToPartitioned'

  def up
    if Gitlab.com_except_jh?
      # GitLab.com: migration was parallelized across four views - find all records by job class name.
      # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224072
      finalize_configurations_for(MIGRATION) do |config|
        ensure_batched_background_migration_is_finished(
          **config.slice(:job_class_name, :table_name, :column_name, :job_arguments).symbolize_keys
        )
      end
    else
      # Self-managed: single migration against the main table.
      ensure_batched_background_migration_is_finished(
        job_class_name: MIGRATION,
        table_name: :merge_request_diff_commits,
        column_name: :merge_request_diff_id,
        job_arguments: ['merge_request_diff_commits_b5377a7a34']
      )
    end
  end

  def down
    # no-op: finalizing a batched background migration is not reversible.
  end

  private

  def finalize_configurations_for(job_class_name)
    Gitlab::Database::BackgroundMigration::BatchedMigration
      .where(job_class_name: job_class_name)
      .find_each { |migration| yield(migration) }
  end
end
