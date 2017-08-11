# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveSystemHookFromGeoNodes < ActiveRecord::Migration
  DOWNTIME = false

  def up
    SystemHook.destroy_all(id: GeoNode.select(:system_hook_id))

    remove_reference :geo_nodes, :system_hook
  end

  def down
    add_column :geo_nodes, :system_hook_id, :integer
  end
end
