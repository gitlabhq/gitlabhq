# frozen_string_literal: true

class AddDeploymentMergeRequestsProjectIdFk < Gitlab::Database::Migration[2.3]
  milestone '18.8'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :deployment_merge_requests, :projects, column: :project_id
  end

  def down
    with_lock_retries do
      remove_foreign_key :deployment_merge_requests, column: :project_id
    end
  end
end
