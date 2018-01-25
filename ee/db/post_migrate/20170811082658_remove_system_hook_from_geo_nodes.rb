# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveSystemHookFromGeoNodes < ActiveRecord::Migration
  DOWNTIME = false

  def up
    execute <<-EOF.strip_heredoc
      DELETE FROM web_hooks
      WHERE id IN (
        SELECT system_hook_id
        FROM geo_nodes
      );
    EOF

    remove_reference :geo_nodes, :system_hook
  end

  def down
    add_column :geo_nodes, :system_hook_id, :integer
  end
end
