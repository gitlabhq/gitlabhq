class AddNotifiedOfOwnActivityToUsers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_column_with_default :users, :notified_of_own_activity, :boolean, default: false
  end

  def down
    remove_column :users, :notified_of_own_activity
  end
end
