# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddMissingOnPrimaryCountsToGeoNodeStatuses < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :geo_node_statuses, :lfs_objects_synced_missing_on_primary_count, :integer
    add_column :geo_node_statuses, :job_artifacts_synced_missing_on_primary_count, :integer
    add_column :geo_node_statuses, :attachments_synced_missing_on_primary_count, :integer
  end
end
