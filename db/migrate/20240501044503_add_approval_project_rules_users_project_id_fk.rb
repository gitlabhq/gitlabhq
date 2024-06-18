# frozen_string_literal: true

class AddApprovalProjectRulesUsersProjectIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.0'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :approval_project_rules_users, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :approval_project_rules_users, column: :project_id
    end
  end
end
