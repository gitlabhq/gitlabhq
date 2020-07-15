# frozen_string_literal: true

class AddDeployKeyIdToPushAccessLevels < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless column_exists?(:protected_branch_push_access_levels, :deploy_key_id)
      add_column :protected_branch_push_access_levels, :deploy_key_id, :integer
    end

    add_concurrent_foreign_key :protected_branch_push_access_levels, :keys, column: :deploy_key_id, on_delete: :cascade
    add_concurrent_index :protected_branch_push_access_levels, :deploy_key_id, name: 'index_deploy_key_id_on_protected_branch_push_access_levels'
  end

  def down
    remove_column :protected_branch_push_access_levels, :deploy_key_id
  end
end
