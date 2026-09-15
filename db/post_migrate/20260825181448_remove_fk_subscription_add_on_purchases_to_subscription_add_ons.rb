# frozen_string_literal: true

class RemoveFkSubscriptionAddOnPurchasesToSubscriptionAddOns < Gitlab::Database::Migration[2.3]
  milestone '19.4'
  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :subscription_add_on_purchases
  TARGET_TABLE_NAME = :subscription_add_ons
  COLUMN = :subscription_add_on_id
  FK_NAME = :fk_410004d68b

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(
        SOURCE_TABLE_NAME,
        TARGET_TABLE_NAME,
        name: FK_NAME
      )
    end
  end

  def down
    add_concurrent_foreign_key(
      SOURCE_TABLE_NAME,
      TARGET_TABLE_NAME,
      column: COLUMN,
      on_delete: :cascade,
      reverse_lock_order: true,
      name: FK_NAME
    )
  end
end
