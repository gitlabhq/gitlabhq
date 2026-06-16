# frozen_string_literal: true

class AddIndexUserAddOnAssignmentVersionsOnOrgPurchaseAndId < Gitlab::Database::Migration[2.3]
  milestone '19.1'
  disable_ddl_transaction!

  OLD_INDEX_NAME = 'idx_user_add_on_assignment_versions_on_organization_id'
  NEW_INDEX_NAME = 'idx_subaoa_versions_on_org_id_purchase_id_and_id'

  def up
    add_concurrent_index :subscription_user_add_on_assignment_versions,
      [:organization_id, :purchase_id, :id],
      name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :subscription_user_add_on_assignment_versions, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :subscription_user_add_on_assignment_versions,
      :organization_id,
      name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :subscription_user_add_on_assignment_versions, NEW_INDEX_NAME
  end
end
