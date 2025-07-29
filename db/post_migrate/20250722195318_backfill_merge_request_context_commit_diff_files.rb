# frozen_string_literal: true

class BackfillMergeRequestContextCommitDiffFiles < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  BATCH_SIZE = 1_000

  def up
    loop do
      sql = <<~SQL
        WITH batch AS (
          SELECT merge_request_context_commit_id, relative_order
          FROM merge_request_context_commit_diff_files
          WHERE project_id IS NULL
          LIMIT #{BATCH_SIZE}
        )
        UPDATE merge_request_context_commit_diff_files
        SET project_id = merge_request_context_commits.project_id
        FROM merge_request_context_commits, batch
        WHERE merge_request_context_commit_diff_files.merge_request_context_commit_id = merge_request_context_commits.id
          AND merge_request_context_commit_diff_files.merge_request_context_commit_id = batch.merge_request_context_commit_id
          AND merge_request_context_commit_diff_files.relative_order = batch.relative_order;
      SQL

      rows_affected = connection.execute(sql).cmd_tuples

      break if rows_affected == 0
    end
  end

  def down
    # This data backfill migration does not require a down method.
  end
end
