# frozen_string_literal: true

class AddIndexToSubscriptionAddOnPurchasesStartedAtAndExpiresOn < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.4'

  INDEX_NAME = 'idx_subscription_add_on_purchases_on_started_on_and_expires_on'

  def up
    add_concurrent_index :subscription_add_on_purchases, [:started_at, :expires_on], name: INDEX_NAME
  end

  def down
    remove_concurrent_index :subscription_add_on_purchases, [:started_at, :expires_on], name: INDEX_NAME
  end
end
