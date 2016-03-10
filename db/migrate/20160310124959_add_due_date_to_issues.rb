class AddDueDateToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :due_date, :date
  end
end
