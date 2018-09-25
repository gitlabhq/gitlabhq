# frozen_string_literal: true
# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveWikisCountAndRepositoriesCountFromGeoNodeStatuses < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    remove_column :geo_node_statuses, :wikis_count, :integer
    remove_column :geo_node_statuses, :repositories_count, :integer
  end

  def down
    add_column :geo_node_statuses, :wikis_count, :integer
    add_column :geo_node_statuses, :repositories_count, :integer
  end
end
