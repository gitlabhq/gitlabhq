# frozen_string_literal: true

class AddClusterIdIndexFkToDeployments < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :deployments, :cluster_id

    add_concurrent_foreign_key :deployments, :clusters, column: :cluster_id, on_delete: :nullify
  end

  def down
    remove_foreign_key :deployments, :clusters

    remove_concurrent_index :deployments, :cluster_id
  end
end
