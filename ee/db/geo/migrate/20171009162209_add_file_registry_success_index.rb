class AddFileRegistrySuccessIndex < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :file_registry, :success
  end

  def down
    remove_concurrent_index :file_registry, :success
  end
end
