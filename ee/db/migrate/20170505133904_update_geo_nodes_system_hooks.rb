# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class UpdateGeoNodesSystemHooks < ActiveRecord::Migration
  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    attrs = {
      push_events: false,
      tag_push_events: false,
      repository_update_events: true
    }
    SystemHook.joins('INNER JOIN geo_nodes ON geo_nodes.system_hook_id = web_hooks.id').update_all(attrs)
  end

  def down
    attrs = {
      push_events: true,
      tag_push_events: true,
      repository_update_events: false
    }
    SystemHook.joins('INNER JOIN geo_nodes ON geo_nodes.system_hook_id = web_hooks.id').update_all(attrs)
  end
end
