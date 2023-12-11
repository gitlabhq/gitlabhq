# frozen_string_literal: true

class FinalizeDeleteOrphanedTransferredProjectApprovalRules < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'DeleteOrphanedTransferredProjectApprovalRules',
      table_name: :approval_project_rules,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
