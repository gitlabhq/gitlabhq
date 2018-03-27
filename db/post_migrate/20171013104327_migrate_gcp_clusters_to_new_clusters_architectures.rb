class MigrateGcpClustersToNewClustersArchitectures < ActiveRecord::Migration
  DOWNTIME = false

  class GcpCluster < ActiveRecord::Base
    self.table_name = 'gcp_clusters'

    belongs_to :project, class_name: 'Project'

    include EachBatch
  end

  class Cluster < ActiveRecord::Base
    self.table_name = 'clusters'

    has_many :cluster_projects, class_name: 'ClustersProject'
    has_many :projects, through: :cluster_projects, class_name: 'Project'
    has_one :provider_gcp, class_name: 'ProvidersGcp'
    has_one :platform_kubernetes, class_name: 'PlatformsKubernetes'

    accepts_nested_attributes_for :provider_gcp
    accepts_nested_attributes_for :platform_kubernetes

    enum platform_type: {
      kubernetes: 1
    }

    enum provider_type: {
      user: 0,
      gcp: 1
    }
  end

  class Project < ActiveRecord::Base
    self.table_name = 'projects'

    has_one :cluster_project, class_name: 'ClustersProject'
    has_one :cluster, through: :cluster_project, class_name: 'Cluster'
  end

  class ClustersProject < ActiveRecord::Base
    self.table_name = 'cluster_projects'

    belongs_to :cluster, class_name: 'Cluster'
    belongs_to :project, class_name: 'Project'
  end

  class ProvidersGcp < ActiveRecord::Base
    self.table_name = 'cluster_providers_gcp'
  end

  class PlatformsKubernetes < ActiveRecord::Base
    self.table_name = 'cluster_platforms_kubernetes'
  end

  def up
    GcpCluster.all.find_each(batch_size: 1) do |gcp_cluster|
      Cluster.create(
        enabled: gcp_cluster.enabled,
        user_id: gcp_cluster.user_id,
        name: gcp_cluster.gcp_cluster_name,
        provider_type: Cluster.provider_types[:gcp],
        platform_type: Cluster.platform_types[:kubernetes],
        projects: [gcp_cluster.project],
        provider_gcp_attributes: {
          status: gcp_cluster.status,
          status_reason: gcp_cluster.status_reason,
          gcp_project_id: gcp_cluster.gcp_project_id,
          zone: gcp_cluster.gcp_cluster_zone,
          num_nodes: gcp_cluster.gcp_cluster_size,
          machine_type: gcp_cluster.gcp_machine_type,
          operation_id: gcp_cluster.gcp_operation_id,
          endpoint: gcp_cluster.endpoint,
          encrypted_access_token: gcp_cluster.encrypted_gcp_token,
          encrypted_access_token_iv: gcp_cluster.encrypted_gcp_token_iv
        },
        platform_kubernetes_attributes: {
          api_url: api_url(gcp_cluster.endpoint),
          ca_cert: gcp_cluster.ca_cert,
          namespace: gcp_cluster.project_namespace,
          username: gcp_cluster.username,
          encrypted_password: gcp_cluster.encrypted_password,
          encrypted_password_iv: gcp_cluster.encrypted_password_iv,
          encrypted_token: gcp_cluster.encrypted_kubernetes_token,
          encrypted_token_iv: gcp_cluster.encrypted_kubernetes_token_iv
        } )
    end
  end

  def down
    execute('DELETE FROM clusters')
  end

  private

  def api_url(endpoint)
    endpoint ? 'https://' + endpoint : nil
  end
end
