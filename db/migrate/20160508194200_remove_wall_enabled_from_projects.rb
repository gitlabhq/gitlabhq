# rubocop:disable all
class RemoveWallEnabledFromProjects < ActiveRecord::Migration
  def change
    remove_column :projects, :wall_enabled, :boolean, default: true, null: false
  end
end
