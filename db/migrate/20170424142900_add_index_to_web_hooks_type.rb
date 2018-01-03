class AddIndexToWebHooksType < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :web_hooks, :type
  end

  def down
    remove_concurrent_index :web_hooks, :type
  end
end
