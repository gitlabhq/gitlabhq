class RemoveCriticalFromIssue < ActiveRecord::Migration
  def up
    remove_column :issues, :critical
  end

  def down
    add_column :issues, :critical, :boolean, :null => true, :default => false
  end
end
