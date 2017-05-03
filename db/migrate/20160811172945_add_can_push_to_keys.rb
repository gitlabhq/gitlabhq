class AddCanPushToKeys < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_column_with_default(:keys, :can_push, :boolean, default: false, allow_null: false)
  end

  def down
    remove_column(:keys, :can_push)
  end
end
