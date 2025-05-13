# frozen_string_literal: true

class FinalizeHkBackfillIssuableSeveritiesNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillIssuableSeveritiesNamespaceId',
      table_name: :issuable_severities,
      column_name: :id,
      job_arguments: [:namespace_id, :issues, :namespace_id, :issue_id],
      finalize: true
    )
  end

  def down; end
end
