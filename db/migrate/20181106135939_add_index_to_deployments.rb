# frozen_string_literal: true

class AddIndexToDeployments < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :deployments, [:project_id, :status, :created_at]
  end

  def down
    remove_concurrent_index :deployments, [:project_id, :status, :created_at]
  end
end
