# frozen_string_literal: true

class AddForeignKeyUserIdOnSubscriptionUserAddOnAssignments < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :subscription_user_add_on_assignments, :users, column: :user_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :subscription_user_add_on_assignments, column: :user_id
    end
  end
end
