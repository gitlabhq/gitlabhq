# frozen_string_literal: true

class IndexDeploymentApprovalsOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '16.11'
  disable_ddl_transaction!

  INDEX_NAME = 'index_deployment_approvals_on_project_id'

  def up
    add_concurrent_index :deployment_approvals, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :deployment_approvals, INDEX_NAME
  end
end
