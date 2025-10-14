# frozen_string_literal: true

class FinalizeBackfillIssueSearchDataNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillIssueSearchDataNamespaceId"

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :issues,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
