class RemoveAdmin < ActiveRecord::Migration
  def up
    drop_table :rails_admin_histories
  end

  def down
    raise "No rollback"
  end
end
