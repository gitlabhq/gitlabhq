module Ci
  class IntegrateClusterService
    def execute(cluster, endpoint, ca_cert, token, username, password)
      kubernetes_service ||= cluster.project.find_or_initialize_service('kubernetes')

      Ci::Cluster.transaction do
        # Update service
        kubernetes_service.attributes = {
          active: true,
          api_url: endpoint,
          ca_pem: ca_cert,
          namespace: cluster.project_namespace,
          token: token
        }

        kubernetes_service.save!

        # Save info in cluster record
        cluster.update!(
          enabled: true,
          service: kubernetes_service,
          username: username,
          password: password,
          kubernetes_token: token,
          ca_cert: ca_cert,
          endpoint: endpoint,
          gcp_token: nil,
          status: Ci::Cluster.statuses[:created]
        )
      end

    rescue ActiveRecord::RecordInvalid => e
      cluster.error!("Failed to integrate cluster into kubernetes_service: #{e.message}")
    end
  end
end
