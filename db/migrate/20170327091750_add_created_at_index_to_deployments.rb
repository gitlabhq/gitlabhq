class AddCreatedAtIndexToDeployments < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :deployments, :created_at
  end

  def down
    remove_concurrent_index :deployments, :created_at
  end
end
