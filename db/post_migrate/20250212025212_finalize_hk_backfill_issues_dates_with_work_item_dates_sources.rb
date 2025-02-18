# frozen_string_literal: true

class FinalizeHkBackfillIssuesDatesWithWorkItemDatesSources < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillIssuesDatesWithWorkItemDatesSources',
      table_name: :work_item_dates_sources,
      column_name: :issue_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
