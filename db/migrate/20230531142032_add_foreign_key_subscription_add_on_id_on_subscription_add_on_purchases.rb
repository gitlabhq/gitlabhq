# frozen_string_literal: true

class AddForeignKeySubscriptionAddOnIdOnSubscriptionAddOnPurchases < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :subscription_add_on_purchases,
      :subscription_add_ons,
      column: :subscription_add_on_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :subscription_add_on_purchases, column: :subscription_add_on_id
    end
  end
end
