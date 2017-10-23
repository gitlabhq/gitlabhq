class MigrateGcpClustersToNewClustersArchitectures < ActiveRecord::Migration
  DOWNTIME = false

  def up
    # TODO: Chnage to something reaistic
    ActiveRecord::Base.connection.select_rows('SELECT * from gcp_clusters;').each do |old_cluster|
      id = old_cluster[0]
      project_id = old_cluster[1]
      user_id = old_cluster[2]
      service_id = old_cluster[3]
      status = old_cluster[4]
      gcp_cluster_size = old_cluster[5]
      created_at = old_cluster[6]
      updated_at = old_cluster[7]
      enabled = old_cluster[8]
      status_reason = old_cluster[9]
      project_namespace = old_cluster[10]
      endpoint = old_cluster[11]
      ca_cert = old_cluster[12]
      encrypted_kubernetes_token = old_cluster[13]
      encrypted_kubernetes_token_iv = old_cluster[14]
      username = old_cluster[15]
      encrypted_password = old_cluster[16]
      encrypted_password_iv = old_cluster[17]
      gcp_project_id = old_cluster[18]
      gcp_cluster_zone = old_cluster[19]
      gcp_cluster_name = old_cluster[20]
      gcp_machine_type = old_cluster[21]
      gcp_operation_id = old_cluster[22]
      encrypted_gcp_token = old_cluster[23]
      encrypted_gcp_token_iv = old_cluster[24]

      cluster = Clusters::Cluster.create!(
        user_id: user_id,
        enabled: enabled,
        name: gcp_cluster_name,
        provider_type: :gcp,
        platform_type: :kubernetes,
        created_at: created_at,
        updated_at: updated_at)

      Clusters::Project.create!(
        cluster: cluster,
        project_id: project_id,
        created_at: created_at,
        updated_at: updated_at)

      Clusters::Platforms::Kubernetes.create!(
        cluster: cluster,
        api_url: 'https://' + endpoint,
        ca_cert: ca_cert,
        namespace: project_namespace,
        username: username,
        encrypted_password: encrypted_password,
        encrypted_password_iv: encrypted_password_iv,
        encrypted_token: encrypted_kubernetes_token,
        encrypted_token_iv: encrypted_kubernetes_token_iv,
        created_at: created_at,
        updated_at: updated_at)

      Clusters::Providers::Gcp.create!(
        cluster: cluster,
        status: status,
        status_reason: status_reason,
        gcp_project_id: gcp_project_id,
        zone: gcp_cluster_zone,
        num_nodes: gcp_cluster_size,
        machine_type: gcp_machine_type,
        operation_id: gcp_operation_id,
        endpoint: endpoint,
        encrypted_access_token: encrypted_gcp_token,
        encrypted_access_token_iv: encrypted_gcp_token_iv,
        created_at: created_at,
        updated_at: updated_at)
    end
  end

  def down
    Clusters::Cluster.delete_all
    Clusters::Project.delete_all
    Clusters::Providers::Gcp.delete_all
    Clusters::Platforms::Kubernetes.delete_all
  end
end
