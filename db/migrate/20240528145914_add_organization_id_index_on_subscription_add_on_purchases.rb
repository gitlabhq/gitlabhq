# frozen_string_literal: true

class AddOrganizationIdIndexOnSubscriptionAddOnPurchases < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!
  INDEX = 'index_add_on_purchases_on_organization_id'

  def up
    add_concurrent_index :subscription_add_on_purchases,
      %i[organization_id],
      name: INDEX
  end

  def down
    remove_concurrent_index_by_name :subscription_add_on_purchases, name: INDEX
  end
end
