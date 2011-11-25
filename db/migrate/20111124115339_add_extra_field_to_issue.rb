class AddExtraFieldToIssue < ActiveRecord::Migration
  def change
    add_column :issues, :branch_name, :string, :null => true
  end
end
