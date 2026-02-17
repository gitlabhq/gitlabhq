# frozen_string_literal: true

class AddIndexOnProvisionedByProjectIdToUserDetails < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  INDEX_NAME = 'index_user_details_on_provisioned_by_project_id'
  milestone '18.9'

  def up
    add_concurrent_index :user_details, :provisioned_by_project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :user_details, name: INDEX_NAME
  end
end
