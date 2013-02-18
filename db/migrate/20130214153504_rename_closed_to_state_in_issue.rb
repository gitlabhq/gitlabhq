class RenameClosedToStateInIssue < ActiveRecord::Migration
  def change
    rename_column :issues, :closed, :state
  end
end
