# rubocop:disable all
class AddStateToMilestone < ActiveRecord::Migration[4.2]
  def change
    add_column :milestones, :state, :string
  end
end
