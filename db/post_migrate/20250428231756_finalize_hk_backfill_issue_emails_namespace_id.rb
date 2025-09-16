# frozen_string_literal: true

class FinalizeHkBackfillIssueEmailsNamespaceId < Gitlab::Database::Migration[2.3]
  milestone '18.0'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillIssueEmailsNamespaceId',
      table_name: :issue_emails,
      column_name: :id,
      job_arguments: [:namespace_id, :issues, :namespace_id, :issue_id],
      finalize: true
    )
  end

  def down; end
end
