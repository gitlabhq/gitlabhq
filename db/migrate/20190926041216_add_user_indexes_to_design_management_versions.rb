# frozen_string_literal: true

class AddUserIndexesToDesignManagementVersions < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :design_management_versions, :users, column: :user_id, on_delete: :nullify
    add_concurrent_index :design_management_versions, :user_id, where: 'user_id IS NOT NULL'
  end

  def down
    remove_concurrent_index :design_management_versions, :user_id
    remove_foreign_key :design_management_versions, column: :user_id
  end
end
