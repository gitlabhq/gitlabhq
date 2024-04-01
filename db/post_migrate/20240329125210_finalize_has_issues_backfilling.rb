# frozen_string_literal: true

class FinalizeHasIssuesBackfilling < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillHasIssuesForExternalIssueLinks"

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :vulnerability_reads,
      column_name: :vulnerability_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
