# frozen_string_literal: true

class AddClusterStatusIndexToDeployments < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :deployments, [:cluster_id, :status]
  end

  def down
    remove_concurrent_index :deployments, [:cluster_id, :status]
  end
end
