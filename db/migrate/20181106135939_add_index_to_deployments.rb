# frozen_string_literal: true

class AddIndexToDeployments < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  SHORT_INDEX_NAME = 'index_deployments_on_deployed_for_finished_at'

  disable_ddl_transaction!

  def up
    add_concurrent_index :deployments, [:project_id, :action, :status]
    add_concurrent_index :deployments, [:environment_id, :action, :status]
    add_concurrent_index :deployments, [:environment_id, :action, :sha]
    add_concurrent_index :deployments, [:project_id, :action, :status, :finished_at], name: SHORT_INDEX_NAME
  end

  def down
    remove_concurrent_index :deployments, [:project_id, :action, :status]
    remove_concurrent_index :deployments, [:environment_id, :action, :status]
    remove_concurrent_index :deployments, [:environment_id, :action, :sha]
    remove_concurrent_index_by_name(:deployments, SHORT_INDEX_NAME)
  end
end
