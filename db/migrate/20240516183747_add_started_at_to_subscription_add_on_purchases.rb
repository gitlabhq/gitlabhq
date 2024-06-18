# frozen_string_literal: true

class AddStartedAtToSubscriptionAddOnPurchases < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :subscription_add_on_purchases, :started_at, :datetime_with_timezone
  end
end
