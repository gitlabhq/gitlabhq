module Ci
  class UpdateClusterService < BaseService
    def execute(cluster)
      Ci::Cluster.transaction do
        if params['enabled'] == 'true'

          cluster.service.attributes = {
            active: true,
            api_url: cluster.endpoint,
            ca_pem: cluster.ca_cert,
            namespace: cluster.project_namespace,
            token: cluster.kubernetes_token
          }

          cluster.service.save!
        else
          cluster.service.update(active: false)
        end

        cluster.update!(enabled: params['enabled'])
      end
    rescue ActiveRecord::RecordInvalid => e
      cluster.errors.add(:base, e.message)
    end
  end
end
