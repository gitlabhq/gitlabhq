class AddInternalIdsToMilestones < ActiveRecord::Migration
  def change
    add_column :milestones, :iid, :integer
  end
end
