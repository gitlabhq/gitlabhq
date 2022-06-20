# frozen_string_literal: true

class RemoveDeploymentClustersClusterIdFk < Gitlab::Database::Migration[2.0]
  FK_NAME = 'fk_rails_4e6243e120'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(
        :deployment_clusters,
        :clusters,
        name: FK_NAME,
        reverse_lock_order: true
      )
    end
  end

  def down
    add_concurrent_foreign_key(
      :deployment_clusters,
      :clusters,
      name: FK_NAME,
      column: :cluster_id,
      target_column: :id,
      on_delete: :cascade
    )
  end
end
