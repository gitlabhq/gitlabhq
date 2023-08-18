# frozen_string_literal: true

class RemoveNotNullFromSubscriptionAddOnPurchasesNamespaceId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    change_column_null :subscription_add_on_purchases, :namespace_id, true
  end

  def down
    change_column_null :subscription_add_on_purchases, :namespace_id, false
  end
end
