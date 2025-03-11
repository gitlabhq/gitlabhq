# frozen_string_literal: true

class PrepareIndexDeploymentMergeRequestsOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  INDEX_NAME = 'index_deployment_merge_requests_on_project_id'

  def up
    prepare_async_index :deployment_merge_requests, :project_id, name: INDEX_NAME
  end

  def down
    unprepare_async_index :deployment_merge_requests, INDEX_NAME
  end
end
