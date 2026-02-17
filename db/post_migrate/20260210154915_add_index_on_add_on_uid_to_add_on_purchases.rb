# frozen_string_literal: true

class AddIndexOnAddOnUidToAddOnPurchases < Gitlab::Database::Migration[2.3]
  milestone '18.9'
  disable_ddl_transaction!

  INDEX_NAME = 'index_subscription_add_on_purchases_on_subscription_add_on_uid'

  def up
    add_concurrent_index :subscription_add_on_purchases, :subscription_add_on_uid, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :subscription_add_on_purchases, INDEX_NAME
  end
end
