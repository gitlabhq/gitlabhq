# frozen_string_literal: true

class CreateSubscriptionAddOnPurchases < Gitlab::Database::Migration[2.1]
  def change
    create_table :subscription_add_on_purchases, if_not_exists: true do |t|
      t.timestamps_with_timezone null: false

      t.bigint  :subscription_add_on_id, null: false
      t.bigint  :namespace_id, null: false
      t.integer :quantity, null: false
      t.date    :expires_on, null: false
      t.text    :purchase_xid, null: false, limit: 255

      t.index :subscription_add_on_id
      t.index :namespace_id
    end
  end
end
