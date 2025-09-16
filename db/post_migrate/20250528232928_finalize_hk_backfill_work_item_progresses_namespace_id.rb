# frozen_string_literal: true

class FinalizeHkBackfillWorkItemProgressesNamespaceId < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillWorkItemProgressesNamespaceId',
      table_name: :work_item_progresses,
      column_name: :issue_id,
      job_arguments: [:namespace_id, :issues, :namespace_id, :issue_id],
      finalize: true
    )
  end

  def down; end
end
