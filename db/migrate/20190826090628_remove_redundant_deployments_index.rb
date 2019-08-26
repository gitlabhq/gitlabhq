# frozen_string_literal: true

class RemoveRedundantDeploymentsIndex < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index :deployments, :cluster_id
  end

  def down
    add_concurrent_index :deployments, :cluster_id
  end
end
