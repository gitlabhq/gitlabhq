# rubocop:disable all
class AddInternalIdsToMilestones < ActiveRecord::Migration[4.2]
  def change
    add_column :milestones, :iid, :integer
  end
end
