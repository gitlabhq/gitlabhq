class MigrateGcpClustersToNewClustersArchitectures < ActiveRecord::Migration
  DOWNTIME = false

  def up
    gcp_clusters = ActiveRecord::Base.connection.select_all('SELECT * from gcp_clusters;')

    rows_for_clusters = Array.new
    rows_for_cluster_projects = Array.new
    rows_for_cluster_providers_gcp = Array.new
    rows_for_cluster_platforms_kubernetes = Array.new

    gcp_clusters.each do |gcp_cluster|
      rows_for_clusters << params_for_clusters(gcp_cluster)
      rows_for_cluster_projects << params_for_cluster_projects(gcp_cluster)
      rows_for_cluster_providers_gcp << params_for_cluster_providers_gcp(gcp_cluster)
      rows_for_cluster_platforms_kubernetes << params_for_cluster_platforms_kubernetes(gcp_cluster)
    end

    Gitlab::Database.bulk_insert('clusters', rows_for_clusters)
    Gitlab::Database.bulk_insert('cluster_projects', rows_for_cluster_projects)
    Gitlab::Database.bulk_insert('cluster_providers_gcp', rows_for_cluster_providers_gcp)
    Gitlab::Database.bulk_insert('cluster_platforms_kubernetes', rows_for_cluster_platforms_kubernetes)
  end

  def down
    execute('DELETE FROM clusters')
  end

  private

  def params_for_clusters(gcp_cluster)
    {
      id: gcp_cluster['id'],
      user_id: gcp_cluster['user_id'],
      enabled: gcp_cluster['enabled'],
      name: gcp_cluster['gcp_cluster_name'],
      provider_type: Clusters::Cluster.provider_types[:gcp],
      platform_type: Clusters::Cluster.platform_types[:kubernetes],
      created_at: gcp_cluster['created_at'],
      updated_at: gcp_cluster['updated_at']
    }
  end

  def params_for_cluster_projects(gcp_cluster)
    {
      cluster_id: gcp_cluster['id'],
      project_id: gcp_cluster['project_id'],
      created_at: gcp_cluster['created_at'],
      updated_at: gcp_cluster['updated_at']
    }
  end

  def params_for_cluster_providers_gcp(gcp_cluster)
    {
      cluster_id: gcp_cluster['id'],
      status: gcp_cluster['status'],
      status_reason: gcp_cluster['status_reason'],
      gcp_project_id: gcp_cluster['gcp_project_id'],
      zone: gcp_cluster['gcp_cluster_zone'],
      num_nodes: gcp_cluster['gcp_cluster_size'],
      machine_type: gcp_cluster['gcp_machine_type'],
      operation_id: gcp_cluster['gcp_operation_id'],
      endpoint: gcp_cluster['endpoint'],
      encrypted_access_token: gcp_cluster['encrypted_gcp_token'],
      encrypted_access_token_iv: gcp_cluster['encrypted_gcp_token_iv'],
      created_at: gcp_cluster['created_at'],
      updated_at: gcp_cluster['updated_at']
    }
  end

  def params_for_cluster_platforms_kubernetes(gcp_cluster)
    {
      cluster_id: gcp_cluster['id'],
      api_url: 'https://' + gcp_cluster['endpoint'],
      ca_cert: gcp_cluster['ca_cert'],
      namespace: gcp_cluster['project_namespace'],
      username: gcp_cluster['username'],
      encrypted_password: gcp_cluster['encrypted_password'],
      encrypted_password_iv: gcp_cluster['encrypted_password_iv'],
      encrypted_token: gcp_cluster['encrypted_kubernetes_token'],
      encrypted_token_iv: gcp_cluster['encrypted_kubernetes_token_iv'],
      created_at: gcp_cluster['created_at'],
      updated_at: gcp_cluster['updated_at']
    }
  end
end
