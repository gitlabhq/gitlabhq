# rubocop:disable Migration/RemoveColumn
# rubocop:disable Migration/UpdateLargeTable
class RevertAddNotifiedOfOwnActivityToUsers < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  def up
    if our_column_exists?
      remove_column :users, :notified_of_own_activity
    end
  end

  def down
    unless our_column_exists?
      add_column_with_default :users, :notified_of_own_activity, :boolean, default: false
    end
  end

  private

  def our_column_exists?
    column_exists?(:users, :notified_of_own_activity)
  end
end
