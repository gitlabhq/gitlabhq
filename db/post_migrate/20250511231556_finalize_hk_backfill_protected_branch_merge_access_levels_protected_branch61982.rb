# frozen_string_literal: true

class FinalizeHkBackfillProtectedBranchMergeAccessLevelsProtectedBranch61982 < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillProtectedBranchMergeAccessLevelsProtectedBranchNamespaceId',
      table_name: :protected_branch_merge_access_levels,
      column_name: :id,
      job_arguments: [:protected_branch_namespace_id, :protected_branches, :namespace_id, :protected_branch_id],
      finalize: true
    )
  end

  def down; end
end
