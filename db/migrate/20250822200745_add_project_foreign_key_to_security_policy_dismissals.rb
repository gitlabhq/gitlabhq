# frozen_string_literal: true

class AddProjectForeignKeyToSecurityPolicyDismissals < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  def up
    add_concurrent_foreign_key :security_policy_dismissals, :projects,
      column: :project_id,
      on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :security_policy_dismissals, column: :project_id
  end
end
