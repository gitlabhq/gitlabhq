# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddWikiInfoToGeoNodeStatuses < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :geo_node_statuses, :wikis_count, :integer
    add_column :geo_node_statuses, :wikis_synced_count, :integer
    add_column :geo_node_statuses, :wikis_failed_count, :integer
  end
end
