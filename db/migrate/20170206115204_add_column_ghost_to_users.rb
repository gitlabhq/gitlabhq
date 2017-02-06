class AddColumnGhostToUsers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :users, :ghost, :boolean, default: false, allow_null: false
  end

  def down
    remove_column :users, :ghost
  end
end
