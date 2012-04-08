class AddMilestoneIdToIssue < ActiveRecord::Migration
  def change
    add_column :issues, :milestone_id, :integer, :null => true
  end
end
