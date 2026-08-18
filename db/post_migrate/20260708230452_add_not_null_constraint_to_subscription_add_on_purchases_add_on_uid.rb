# frozen_string_literal: true

class AddNotNullConstraintToSubscriptionAddOnPurchasesAddOnUid < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.3'

  def up
    add_not_null_constraint :subscription_add_on_purchases, :subscription_add_on_uid
  end

  def down
    remove_not_null_constraint :subscription_add_on_purchases, :subscription_add_on_uid
  end
end
