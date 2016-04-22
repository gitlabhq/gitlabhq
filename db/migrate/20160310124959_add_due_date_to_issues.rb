class AddDueDateToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :due_date, :date
    add_index :issues, :due_date
  end
end
