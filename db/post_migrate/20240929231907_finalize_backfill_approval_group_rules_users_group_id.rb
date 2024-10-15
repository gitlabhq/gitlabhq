# frozen_string_literal: true

class FinalizeBackfillApprovalGroupRulesUsersGroupId < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillApprovalGroupRulesUsersGroupId',
      table_name: :approval_group_rules_users,
      column_name: :id,
      job_arguments: [:group_id, :approval_group_rules, :group_id, :approval_group_rule_id],
      finalize: true
    )
  end

  def down; end
end
