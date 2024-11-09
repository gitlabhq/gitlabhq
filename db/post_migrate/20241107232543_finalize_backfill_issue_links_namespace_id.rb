# frozen_string_literal: true

class FinalizeBackfillIssueLinksNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillIssueLinksNamespaceId',
      table_name: :issue_links,
      column_name: :id,
      job_arguments: [:namespace_id, :issues, :namespace_id, :source_id],
      finalize: true
    )
  end

  def down; end
end
