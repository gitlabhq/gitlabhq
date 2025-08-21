# frozen_string_literal: true

class FinalizeHkBackfillProtectedBranchUnprotectAccessLevelsProtectedBr56778 < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillProtectedBranchUnprotectAccessLevelsProtectedBranchNamespaceId',
      table_name: :protected_branch_unprotect_access_levels,
      column_name: :id,
      job_arguments: [:protected_branch_namespace_id, :protected_branches, :namespace_id, :protected_branch_id],
      finalize: true
    )
  end

  def down; end
end
