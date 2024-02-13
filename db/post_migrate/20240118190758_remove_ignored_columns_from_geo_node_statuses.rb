# frozen_string_literal: true

class RemoveIgnoredColumnsFromGeoNodeStatuses < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.9'

  IGNORED_COLLUMNS = [
    :container_repositories_count,
    :container_repositories_failed_count,
    :container_repositories_registry_count,
    :container_repositories_synced_count,
    :job_artifacts_count,
    :job_artifacts_failed_count,
    :job_artifacts_synced_count,
    :job_artifacts_synced_missing_on_primary_count,
    :lfs_objects_count,
    :lfs_objects_failed_count,
    :lfs_objects_synced_count,
    :lfs_objects_synced_missing_on_primary_count
  ]

  def up
    IGNORED_COLLUMNS.each do |column_name|
      remove_column :geo_node_statuses, column_name, if_exists: true
    end
  end

  def down
    IGNORED_COLLUMNS.each do |column_name|
      add_column :geo_node_statuses, column_name, :integer, if_not_exists: true
    end
  end
end
