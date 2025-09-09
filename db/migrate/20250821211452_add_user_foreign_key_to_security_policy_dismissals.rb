# frozen_string_literal: true

class AddUserForeignKeyToSecurityPolicyDismissals < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  def up
    add_concurrent_foreign_key :security_policy_dismissals, :users,
      column: :user_id,
      on_delete: :nullify
  end

  def down
    remove_foreign_key_if_exists :security_policy_dismissals, column: :user_id
  end
end
