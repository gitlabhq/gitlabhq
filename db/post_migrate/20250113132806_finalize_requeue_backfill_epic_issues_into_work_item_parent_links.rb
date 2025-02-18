# frozen_string_literal: true

class FinalizeRequeueBackfillEpicIssuesIntoWorkItemParentLinks < Gitlab::Database::Migration[2.2]
  MIGRATION = 'RequeueBackfillEpicIssuesIntoWorkItemParentLinks'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.9'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :epic_issues,
      column_name: :id,
      job_arguments: [nil],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
