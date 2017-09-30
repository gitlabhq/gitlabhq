class WaitForClusterCreationWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  INITIAL_INTERVAL = 2.minutes
  EAGER_INTERVAL = 10.seconds
  TIMEOUT = 20.minutes

  def perform(cluster_id)
    cluster = Ci::Cluster.find_by_id(cluster_id)

    unless cluster
      return Rails.logger.error "Cluster object is not found; #{cluster_id}"
    end

    api_client = 
      GoogleApi::CloudPlatform::Client.new(cluster.gcp_token, nil)

    operation = api_client.projects_zones_operations(
        cluster.gcp_project_id,
        cluster.cluster_zone,
        cluster.gcp_operation_id
      )

    if operation.is_a?(StandardError)
      return cluster.error!("Failed to request to CloudPlatform; #{operation.message}")
    end

    case operation.status
    when 'DONE'
      integrate(api_client, cluster)
    when 'RUNNING'
      if Time.now < operation.start_time.to_time + TIMEOUT
        WaitForClusterCreationWorker.perform_in(EAGER_INTERVAL, cluster.id)
      else
        return cluster.error!("Cluster creation time exceeds timeout; #{TIMEOUT}")
      end
    else
      return cluster.error!("Unexpected operation status; #{operation.status_message}")
    end
  end

  def integrate(api_client, cluster)
    # Get cluster details (end point, etc)
    gke_cluster = api_client.projects_zones_clusters_get(
        cluster.gcp_project_id,
        cluster.cluster_zone,
        cluster.cluster_name
      )

    if gke_cluster.is_a?(StandardError)
      return cluster.error!("Failed to request to CloudPlatform; #{gke_cluster.message}")
    end

    # Get k8s token
    kubernetes_token = ''
    KubernetesService.new.tap do |ks|
      ks.api_url = 'https://' + gke_cluster.endpoint
      ks.ca_pem = Base64.decode64(gke_cluster.master_auth.cluster_ca_certificate)
      ks.username = gke_cluster.master_auth.username
      ks.password = gke_cluster.master_auth.password
      secrets = ks.read_secrets
      secrets.each do |secret|
        name = secret.dig('metadata', 'name')
        if /default-token/ =~ name
          token_base64 = secret.dig('data', 'token')
          kubernetes_token = Base64.decode64(token_base64)
          break
        end
      end
    end

    unless kubernetes_token
      return cluster.error!('Failed to get a default token of kubernetes')
    end

    # k8s endpoint, ca_cert
    endpoint = 'https://' + gke_cluster.endpoint
    ca_cert = Base64.decode64(gke_cluster.master_auth.cluster_ca_certificate)
    username = gke_cluster.master_auth.username
    password = gke_cluster.master_auth.password

    Ci::IntegrateClusterService.new.execute(cluster, endpoint, ca_cert, kubernetes_token, username, password)
  end
end
