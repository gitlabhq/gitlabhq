# frozen_string_literal: true

class AddIndexToDeployments < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :deployments, [:project_id, :action, :status]
    add_concurrent_index :deployments, [:environment_id, :action, :status]
    add_concurrent_index :deployments, [:environment_id, :action, :sha]
    add_concurrent_index :deployments, [:finished_at]
  end

  def down
    remove_concurrent_index :deployments, [:project_id, :action, :status]
    remove_concurrent_index :deployments, [:environment_id, :action, :status]
    remove_concurrent_index :deployments, [:environment_id, :action, :sha]
    remove_concurrent_index :deployments, [:finished_at]
  end
end
