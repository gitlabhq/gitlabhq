# frozen_string_literal: true

class AddProtectedEnvironmentApprovalRulesProtectedEnvironmentProjectIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :protected_environment_approval_rules, :projects,
      column: :protected_environment_project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :protected_environment_approval_rules, column: :protected_environment_project_id
    end
  end
end
