# frozen_string_literal: true

class AddForeignKeyAddOnPurchaseIdOnSubscriptionUserAddOnAssignments < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :subscription_user_add_on_assignments, :subscription_add_on_purchases,
      column: :add_on_purchase_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :subscription_user_add_on_assignments, column: :add_on_purchase_id
    end
  end
end
