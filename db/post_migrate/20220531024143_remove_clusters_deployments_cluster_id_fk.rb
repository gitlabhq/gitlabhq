# frozen_string_literal: true

class RemoveClustersDeploymentsClusterIdFk < Gitlab::Database::Migration[2.0]
  FK_NAME = 'fk_289bba3222'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(
        :deployments,
        :clusters,
        name: FK_NAME,
        reverse_lock_order: true
      )
    end
  end

  def down
    add_concurrent_foreign_key(
      :deployments,
      :clusters,
      name: FK_NAME,
      column: :cluster_id,
      target_column: :id,
      on_delete: :nullify
    )
  end
end
