class AddNotifiedOfOwnActivityDefault < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  def up
    begin
      update_column_in_batches(:users, :notified_of_own_activity, false) do |table, query|
        query.where(table[:notified_of_own_activity].eq(nil))
      end

      change_column :users, :notified_of_own_activity, :boolean, default: false, null: false
    end
  end

  def down
    change_column_default :users, :notified_of_own_activity, nil
  end
end
