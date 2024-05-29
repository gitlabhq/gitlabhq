# frozen_string_literal: true

class AddIndexToSubscriptionAddOnPurchasesExpiresOn < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.1'

  INDEX_NAME = 'index_subscription_addon_purchases_on_expires_on'

  def up
    add_concurrent_index :subscription_add_on_purchases, :expires_on, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :subscription_add_on_purchases, :expires_on, name: INDEX_NAME
  end
end
