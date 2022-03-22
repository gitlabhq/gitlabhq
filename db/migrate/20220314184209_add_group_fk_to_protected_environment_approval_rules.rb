# frozen_string_literal: true

class AddGroupFkToProtectedEnvironmentApprovalRules < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :protected_environment_approval_rules, :namespaces, column: :group_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :protected_environment_approval_rules, column: :group_id
    end
  end
end
