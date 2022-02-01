# frozen_string_literal: true

class AddUserDetailsProvisioningIndex < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'idx_user_details_on_provisioned_by_group_id_user_id'
  OLD_INDEX_NAME = 'index_user_details_on_provisioned_by_group_id'

  def up
    add_concurrent_index :user_details, [:provisioned_by_group_id, :user_id], name: INDEX_NAME
    remove_concurrent_index_by_name :user_details, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :user_details, :provisioned_by_group_id, name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :user_details, INDEX_NAME
  end
end
