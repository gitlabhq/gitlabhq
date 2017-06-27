class AddGroupIdToMilestones < ActiveRecord::Migration
  DOWNTIME = false

  def change
    change_column_null :milestones, :project_id, true
    add_column :milestones, :group_id, :integer
    add_column :issues, :group_milestone_id, :integer
    add_column :merge_requests, :group_milestone_id, :integer
  end
end
