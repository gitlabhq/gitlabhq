# frozen_string_literal: true

class AddDeploymentClustersProjectIdFk < Gitlab::Database::Migration[2.3]
  milestone '18.8'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :deployment_clusters, :projects, column: :project_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :deployment_clusters, column: :project_id
    end
  end
end
