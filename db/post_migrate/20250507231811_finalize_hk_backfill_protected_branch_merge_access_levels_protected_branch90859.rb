# frozen_string_literal: true

class FinalizeHkBackfillProtectedBranchMergeAccessLevelsProtectedBranch90859 < Gitlab::Database::Migration[2.3]
  milestone '18.0'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillProtectedBranchMergeAccessLevelsProtectedBranchProjectId',
      table_name: :protected_branch_merge_access_levels,
      column_name: :id,
      job_arguments: [:protected_branch_project_id, :protected_branches, :project_id, :protected_branch_id],
      finalize: true
    )
  end

  def down; end
end
