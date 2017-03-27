class AddCreatedAtIndexToDeployments < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    add_concurrent_index :deployments, :created_at
  end
end
