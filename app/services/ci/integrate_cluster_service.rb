module Ci
  class IntegrateClusterService
    def execute(cluster, endpoint, ca_cert, token, username, password)
      Gcp::Cluster.transaction do
        cluster.created!(endpoint, ca_cert, token, username, password)

        cluster.service.update!(
          active: true,
          api_url: cluster.api_url,
          ca_pem: ca_cert,
          namespace: cluster.project_namespace,
          token: token)
      end
    rescue ActiveRecord::RecordInvalid => e
      cluster.error!("Failed to integrate cluster into kubernetes_service: #{e.message}")
    end
  end
end
