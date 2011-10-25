class AddHighLabelToIssue < ActiveRecord::Migration
  def change
    add_column :issues, :critical, :boolean, :default => false, :null => false
  end
end
