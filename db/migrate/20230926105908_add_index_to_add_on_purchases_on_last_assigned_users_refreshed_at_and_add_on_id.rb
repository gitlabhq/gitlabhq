# frozen_string_literal: true

class AddIndexToAddOnPurchasesOnLastAssignedUsersRefreshedAtAndAddOnId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'idx_addon_purchases_on_last_refreshed_at_desc_nulls_last'

  def up
    add_concurrent_index :subscription_add_on_purchases, %i[last_assigned_users_refreshed_at],
      order: { last_assigned_users_refreshed_at: 'DESC NULLS LAST' },
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :subscription_add_on_purchases, INDEX_NAME
  end
end
