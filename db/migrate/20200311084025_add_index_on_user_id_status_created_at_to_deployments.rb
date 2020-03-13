# frozen_string_literal: true

class AddIndexOnUserIdStatusCreatedAtToDeployments < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :deployments, [:user_id, :status, :created_at]
  end

  def down
    remove_concurrent_index :deployments, [:user_id, :status, :created_at]
  end
end
