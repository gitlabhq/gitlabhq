# frozen_string_literal: true

class AddLastAssignedUsersRefreshedAtToSubscriptionAddOnPurchases < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column(:subscription_add_on_purchases, :last_assigned_users_refreshed_at, :datetime_with_timezone)
  end
end
