# frozen_string_literal: true

class AddProvisionedByGroupToUserDetails < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_user_details_on_provisioned_by_group_id'

  disable_ddl_transaction!

  def up
    unless column_exists?(:user_details, :provisioned_by_group_id)
      with_lock_retries { add_column(:user_details, :provisioned_by_group_id, :integer, limit: 8) }
    end

    add_concurrent_index :user_details, :provisioned_by_group_id, name: INDEX_NAME
    add_concurrent_foreign_key :user_details, :namespaces, column: :provisioned_by_group_id, on_delete: :nullify
  end

  def down
    with_lock_retries { remove_foreign_key_without_error :user_details, column: :provisioned_by_group_id }

    remove_concurrent_index_by_name :user_details, INDEX_NAME

    if column_exists?(:user_details, :provisioned_by_group_id)
      with_lock_retries { remove_column(:user_details, :provisioned_by_group_id) }
    end
  end
end
