class AddStatusToIssue < ActiveRecord::Migration
  def change
    add_column :issues, :closed, :boolean, :default => false, :null => false
  end
end
