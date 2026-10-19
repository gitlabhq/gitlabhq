# frozen_string_literal: true

class FinalizeHkBackfillMissedDiffCommitsToPartitioned < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillMissedDiffCommitsToPartitioned',
      table_name: :merge_request_diff_commits_archived,
      column_name: :merge_request_diff_id,
      job_arguments: [:merge_request_diff_commits],
      finalize: true
    )
  end

  def down; end
end
