# rubocop:disable all
class AddMirrorTriggerBuildsToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :mirror_trigger_builds, :boolean, default: false, null: false
  end
end
