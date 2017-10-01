module Ci
  class UpdateClusterService < BaseService
    def execute(cluster)
      Ci::Cluster.transaction do
        cluster.update!(enabled: params['enabled'])

        if params['enabled'] == 'true'
          cluster.service.update!(
            active: true,
            api_url: cluster.api_url,
            ca_pem: cluster.ca_cert,
            namespace: cluster.project_namespace,
            token: cluster.kubernetes_token)
        else
          cluster.service.update(active: false)
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      cluster.errors.add(:base, e.message)
    end
  end
end
