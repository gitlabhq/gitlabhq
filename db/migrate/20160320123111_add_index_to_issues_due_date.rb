class AddIndexToIssuesDueDate < ActiveRecord::Migration
  def change
    add_index :issues, :due_date
  end
end
