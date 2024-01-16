# frozen_string_literal: true

class FinalizeMergeRequestDiffsProjectIdBackfill < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillMergeRequestDiffsProjectId',
      table_name: :merge_request_diffs,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
