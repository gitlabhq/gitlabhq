# frozen_string_literal: true

class AddNotNullToSubscriptionAddOnPurchasesStartedAt < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!

  DEPENDENT_BATCHED_BACKGROUND_MIGRATIONS = ["20241203172717"]
  TABLE_NAME = :subscription_add_on_purchases
  COLUMN_NAME = :started_at

  def up
    add_not_null_constraint(TABLE_NAME, COLUMN_NAME)
  end

  def down
    remove_not_null_constraint(TABLE_NAME, COLUMN_NAME)
  end
end
