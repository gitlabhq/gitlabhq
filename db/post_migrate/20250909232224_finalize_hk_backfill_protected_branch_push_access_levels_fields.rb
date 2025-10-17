# frozen_string_literal: true

class FinalizeHkBackfillProtectedBranchPushAccessLevelsFields < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillProtectedBranchPushAccessLevelsFields',
      table_name: :protected_branch_push_access_levels,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
