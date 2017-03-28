class ReaddNotifiedOfOwnActivityToUsers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  def change
    add_column :users, :notified_of_own_activity, :boolean
  end
end
