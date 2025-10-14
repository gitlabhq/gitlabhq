# frozen_string_literal: true

class AddFkDefaultUserAddOnAssignmentToUserPreferences < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.2'

  def up
    add_concurrent_foreign_key :user_preferences, :subscription_user_add_on_assignments,
      column: :default_duo_add_on_assignment_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :user_preferences, column: :default_duo_add_on_assignment_id
    end
  end
end
