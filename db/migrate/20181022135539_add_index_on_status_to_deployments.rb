# frozen_string_literal: true

class AddIndexOnStatusToDeployments < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :deployments, [:project_id, :status]
    add_concurrent_index :deployments, [:environment_id, :status]
  end

  def down
    remove_concurrent_index :deployments, [:project_id, :status]
    remove_concurrent_index :deployments, [:environment_id, :status]
  end
end
