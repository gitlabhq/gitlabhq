# frozen_string_literal: true

class FinalizeBackfillExternalStatusChecksProtectedBranchesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.8'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillExternalStatusChecksProtectedBranchesProjectId',
      table_name: :external_status_checks_protected_branches,
      column_name: :id,
      job_arguments: [:project_id, :external_status_checks, :project_id, :external_status_check_id],
      finalize: true
    )
  end

  def down; end
end
