# frozen_string_literal: true

class AddTrialToSubscriptionAddOnPurchases < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  enable_lock_retries!

  def change
    add_column :subscription_add_on_purchases, :trial, :boolean, default: false, null: false
  end
end
