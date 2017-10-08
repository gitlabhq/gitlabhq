# rubocop:disable all
class AddDueDateToIssues < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :due_date, :date
    add_index :issues, :due_date
  end
end
