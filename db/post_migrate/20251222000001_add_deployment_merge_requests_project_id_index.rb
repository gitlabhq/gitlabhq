# frozen_string_literal: true

class AddDeploymentMergeRequestsProjectIdIndex < Gitlab::Database::Migration[2.3]
  milestone '18.8'
  disable_ddl_transaction!

  INDEX = 'index_deployment_merge_requests_on_project_id'

  def up
    add_concurrent_index :deployment_merge_requests, :project_id, name: INDEX # rubocop:disable Migration/PreventIndexCreation -- Required for sharding key
  end

  def down
    remove_concurrent_index :deployment_merge_requests, :project_id, name: INDEX
  end
end
