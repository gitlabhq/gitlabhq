# rubocop:disable all
class RemoveClosedFromMilestone < ActiveRecord::Migration[4.2]
  def up
    remove_column :milestones, :closed
  end

  def down
    add_column :milestones, :closed, :boolean
  end
end
