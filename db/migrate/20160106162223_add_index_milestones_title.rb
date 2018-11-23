# rubocop:disable all
class AddIndexMilestonesTitle < ActiveRecord::Migration[4.2]
  def change
    add_index :milestones, :title
  end
end
