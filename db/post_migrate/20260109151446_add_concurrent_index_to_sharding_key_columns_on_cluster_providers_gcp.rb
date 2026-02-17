# frozen_string_literal: true

class AddConcurrentIndexToShardingKeyColumnsOnClusterProvidersGcp < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.9'

  TABLE_NAME = 'cluster_providers_gcp'

  ORGANIZATION_INDEX = 'idx_cluster_providers_gcp_on_organization_id'
  GROUP_INDEX = 'idx_cluster_providers_gcp_on_group_id'
  PROJECT_INDEX = 'idx_cluster_providers_gcp_on_project_id'

  def up
    add_concurrent_index TABLE_NAME, :organization_id, name: ORGANIZATION_INDEX
    add_concurrent_index TABLE_NAME, :group_id, name: GROUP_INDEX
    add_concurrent_index TABLE_NAME, :project_id, name: PROJECT_INDEX
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, PROJECT_INDEX
    remove_concurrent_index_by_name TABLE_NAME, GROUP_INDEX
    remove_concurrent_index_by_name TABLE_NAME, ORGANIZATION_INDEX
  end
end
