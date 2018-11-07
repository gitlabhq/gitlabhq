# frozen_string_literal: true

class AddIndexToDeployments < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :deployments, [:project_id, :status, :id]
    add_concurrent_index :deployments, [:project_id, :status, :iid]
    add_concurrent_index :deployments, [:environment_id, :status, :id]
    add_concurrent_index :deployments, [:environment_id, :status, :iid]
    add_concurrent_index :deployments, [:environment_id, :sha]
  end

  def down
    remove_concurrent_index :deployments, [:project_id, :status, :id]
    remove_concurrent_index :deployments, [:project_id, :status, :iid]
    remove_concurrent_index :deployments, [:environment_id, :status, :id]
    remove_concurrent_index :deployments, [:environment_id, :status, :iid]
    remove_concurrent_index :deployments, [:environment_id, :sha]
  end
end
