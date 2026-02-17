# frozen_string_literal: true

class AddAddOnNameUidToAddOnPurchases < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  def up
    add_column :subscription_add_on_purchases, :subscription_add_on_uid, :smallint, if_not_exists: true
  end

  def down
    remove_column :subscription_add_on_purchases, :subscription_add_on_uid, if_exists: true
  end
end
