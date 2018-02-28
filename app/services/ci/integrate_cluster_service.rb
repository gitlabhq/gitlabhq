module Ci
  class IntegrateClusterService
    def execute(cluster, endpoint, ca_cert, token, username, password)
      Gcp::Cluster.transaction do
        cluster.update!(
          enabled: true,
          endpoint: endpoint,
          ca_cert: ca_cert,
          kubernetes_token: token,
          username: username,
          password: password,
          service: cluster.project.find_or_initialize_service('kubernetes'),
          status_event: :make_created)

        cluster.service.update!(
          active: true,
          api_url: cluster.api_url,
          ca_pem: ca_cert,
          namespace: cluster.project_namespace,
          token: token)
      end
    rescue ActiveRecord::RecordInvalid => e
      cluster.make_errored!("Failed to integrate cluster into kubernetes_service: #{e.message}")
    end
  end
end
