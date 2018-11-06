# frozen_string_literal: true

class AddIndexToDeployments < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  SHORT_INDEX_NAME_FOR_ENVIRONMENT_ID = 'index_deployments_on_env_deployed_for_id'
  SHORT_INDEX_NAME_FOR_ENVIRONMENT_IID = 'index_deployments_on_env_deployed_for_iid'
  SHORT_INDEX_NAME_FOR_PROJECT_FINISHED_AT = 'index_deployments_on_prj_deployed_for_finished_at'

  disable_ddl_transaction!

  def up
    add_concurrent_index :deployments, [:project_id, :action, :status, :id]
    add_concurrent_index :deployments, [:project_id, :action, :status, :iid]
    add_concurrent_index :deployments, [:project_id, :action, :status, :finished_at], name: SHORT_INDEX_NAME_FOR_PROJECT_FINISHED_AT
    add_concurrent_index :deployments, [:environment_id, :action, :status, :id], name: SHORT_INDEX_NAME_FOR_ENVIRONMENT_ID
    add_concurrent_index :deployments, [:environment_id, :action, :status, :iid], name: SHORT_INDEX_NAME_FOR_ENVIRONMENT_IID
    add_concurrent_index :deployments, [:environment_id, :action, :sha]
  end

  def down
    remove_concurrent_index :deployments, [:project_id, :action, :status, :id]
    remove_concurrent_index :deployments, [:project_id, :action, :status, :iid]
    remove_concurrent_index_by_name(:deployments, SHORT_INDEX_NAME_FOR_PROJECT_FINISHED_AT)
    remove_concurrent_index_by_name(:deployments, SHORT_INDEX_NAME_FOR_ENVIRONMENT_ID)
    remove_concurrent_index_by_name(:deployments, SHORT_INDEX_NAME_FOR_ENVIRONMENT_IID)
    remove_concurrent_index :deployments, [:environment_id, :action, :sha]
  end
end
