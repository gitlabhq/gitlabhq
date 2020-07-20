# frozen_string_literal: true

class AddIndexOnIdAndStatusAndCreatedAtToDeployments < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :deployments, [:id, :status, :created_at]
    remove_concurrent_index :deployments, [:id, :status]
  end

  def down
    add_concurrent_index :deployments, [:id, :status]
    remove_concurrent_index :deployments, [:id, :status, :created_at]
  end
end
