# frozen_string_literal: true

class RemoveSubscriptionAddOnIdIndexFromSubscriptionAddOnPurchases < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.4'

  INDEX_NAME = 'index_subscription_add_on_purchases_on_subscription_add_on_id'

  def up
    remove_concurrent_index :subscription_add_on_purchases, :subscription_add_on_id,
      name: INDEX_NAME
  end

  def down
    add_concurrent_index :subscription_add_on_purchases, :subscription_add_on_id,
      name: INDEX_NAME
  end
end
