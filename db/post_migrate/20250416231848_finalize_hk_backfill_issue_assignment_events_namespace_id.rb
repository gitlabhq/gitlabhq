# frozen_string_literal: true

class FinalizeHkBackfillIssueAssignmentEventsNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillIssueAssignmentEventsNamespaceId',
      table_name: :issue_assignment_events,
      column_name: :id,
      job_arguments: [:namespace_id, :issues, :namespace_id, :issue_id],
      finalize: true
    )
  end

  def down; end
end
