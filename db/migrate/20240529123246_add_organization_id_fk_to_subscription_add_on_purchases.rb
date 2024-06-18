# frozen_string_literal: true

class AddOrganizationIdFkToSubscriptionAddOnPurchases < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(
      :subscription_add_on_purchases,
      :organizations,
      column: :organization_id,
      on_delete: :cascade
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(
        :subscription_add_on_purchases,
        column: :organization_id
      )
    end
  end
end
