class AddIndexToMilestones < ActiveRecord::Migration
  def change
    add_index :milestones, :title
    add_index :labels, :title
  end
end
