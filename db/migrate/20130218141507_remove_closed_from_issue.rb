class RemoveClosedFromIssue < ActiveRecord::Migration
  def up
    remove_column :issues, :closed
  end

  def down
    add_column :issues, :closed, :boolean
  end
end
