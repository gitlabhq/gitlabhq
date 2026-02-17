# frozen_string_literal: true

class AddShardingKeyColumnsToClustersKubernetesNamespaces < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  TABLE_NAME = 'clusters_kubernetes_namespaces'

  def up
    add_column TABLE_NAME, :organization_id, :bigint
    add_column TABLE_NAME, :group_id, :bigint
    add_column TABLE_NAME, :sharding_project_id, :bigint
  end

  def down
    remove_column TABLE_NAME, :sharding_project_id
    remove_column TABLE_NAME, :group_id
    remove_column TABLE_NAME, :organization_id
  end
end
