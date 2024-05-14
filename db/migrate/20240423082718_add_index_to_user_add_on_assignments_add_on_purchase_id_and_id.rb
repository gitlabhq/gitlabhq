# frozen_string_literal: true

class AddIndexToUserAddOnAssignmentsAddOnPurchaseIdAndId < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  disable_ddl_transaction!

  INDEX_NAME = 'idx_user_add_on_assignments_on_add_on_purchase_id_and_id'

  def up
    add_concurrent_index :subscription_user_add_on_assignments, [:add_on_purchase_id, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :subscription_user_add_on_assignments, INDEX_NAME
  end
end
