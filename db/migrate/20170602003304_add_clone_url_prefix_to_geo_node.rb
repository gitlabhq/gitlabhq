# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddCloneUrlPrefixToGeoNode < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :geo_nodes, :clone_url_prefix, :string
  end
end
