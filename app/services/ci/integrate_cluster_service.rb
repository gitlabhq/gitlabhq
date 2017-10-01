module Ci
  class IntegrateClusterService
    def execute(cluster, endpoint, ca_cert, token, username, password)
      Ci::Cluster.transaction do
        kubernetes_service ||=
          cluster.project.find_or_initialize_service('kubernetes')

        cluster.update!(
          enabled: true,
          service: kubernetes_service,
          username: username,
          password: password,
          kubernetes_token: token,
          ca_cert: ca_cert,
          endpoint: endpoint,
          gcp_token: nil,
          gcp_operation_id: nil,
          status: Ci::Cluster.statuses[:created])

        kubernetes_service.update!(
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
