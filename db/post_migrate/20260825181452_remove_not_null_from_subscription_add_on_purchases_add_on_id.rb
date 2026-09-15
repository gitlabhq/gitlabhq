# frozen_string_literal: true

class RemoveNotNullFromSubscriptionAddOnPurchasesAddOnId < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def up
    change_column_null :subscription_add_on_purchases, :subscription_add_on_id, true
  end

  def down
    change_column_null :subscription_add_on_purchases, :subscription_add_on_id, false
  end
end
