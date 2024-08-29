# frozen_string_literal: true

class AddCompositeIndexToSubscriptionAddOnPurchases < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.4'

  INDEX_NAME = 'index_subscription_add_on_purchases_on_namespace_id_add_on_id'

  def up
    add_concurrent_index :subscription_add_on_purchases,
      [:namespace_id, :subscription_add_on_id],
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index :subscription_add_on_purchases,
      [:namespace_id, :subscription_add_on_id],
      name: INDEX_NAME
  end
end
