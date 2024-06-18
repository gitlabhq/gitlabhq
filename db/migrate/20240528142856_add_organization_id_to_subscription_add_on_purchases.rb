# frozen_string_literal: true

class AddOrganizationIdToSubscriptionAddOnPurchases < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  DEFAULT_ORGANIZATION_ID = 1

  enable_lock_retries!

  def change
    add_column :subscription_add_on_purchases, :organization_id, :bigint, default: DEFAULT_ORGANIZATION_ID, null: false
  end
end
