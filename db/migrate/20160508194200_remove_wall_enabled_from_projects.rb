# rubocop:disable all
class RemoveWallEnabledFromProjects < ActiveRecord::Migration[4.2]
  def change
    remove_column :projects, :wall_enabled, :boolean, default: true, null: false
  end
end
