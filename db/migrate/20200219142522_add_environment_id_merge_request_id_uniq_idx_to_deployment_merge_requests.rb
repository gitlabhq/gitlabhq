# frozen_string_literal: true

class AddEnvironmentIdMergeRequestIdUniqIdxToDeploymentMergeRequests < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :deployment_merge_requests, [:environment_id, :merge_request_id], unique: true, name: 'idx_environment_merge_requests_unique_index'
  end

  def down
    remove_concurrent_index_by_name :deployment_merge_requests, 'idx_environment_merge_requests_unique_index'
  end
end
