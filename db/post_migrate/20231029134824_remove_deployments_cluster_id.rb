# frozen_string_literal: true

class RemoveDeploymentsClusterId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.7'

  def up
    with_lock_retries do
      remove_column :deployments, :cluster_id, if_exists: true
    end
  end

  def down
    with_lock_retries do
      add_column :deployments, :cluster_id, :integer, if_not_exists: true
    end

    add_concurrent_index(:deployments, [:cluster_id, :status])
  end
end
