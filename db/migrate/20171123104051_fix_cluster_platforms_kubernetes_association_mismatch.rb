class FixClusterPlatformsKubernetesAssociationMismatch < ActiveRecord::Migration
  DOWNTIME = false

  class GcpCluster < ActiveRecord::Base
    self.table_name = 'gcp_clusters'

    belongs_to :project, class_name: 'Project'
  end

  class Cluster < ActiveRecord::Base
    self.table_name = 'clusters'

    has_one :provider_gcp, class_name: 'ProvidersGcp'
    has_one :platform_kubernetes, class_name: 'PlatformsKubernetes'
  end

  class ProvidersGcp < ActiveRecord::Base
    self.table_name = 'cluster_providers_gcp'

    belongs_to :cluster, inverse_of: :provider_gcp, class_name: 'Cluster'
  end

  class PlatformsKubernetes < ActiveRecord::Base
    include EachBatch

    self.table_name = 'cluster_platforms_kubernetes'

    belongs_to :cluster, inverse_of: :platform_kubernetes, class_name: 'Cluster'
  end

  def up
    PlatformsKubernetes.all.find_each(batch_size: 1) do |platforms_kubernetes|
      # This is the culprit. See https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/15566
      gcp_cluster = GcpCluster.find_by_id(platforms_kubernetes.cluster_id)

      provider_gcp = ProvidersGcp.joins(:cluster)
        .where(gcp_project_id: gcp_cluster.gcp_project_id,
               zone: gcp_cluster.gcp_cluster_zone,
               num_nodes: gcp_cluster.gcp_cluster_size,
               machine_type: gcp_cluster.gcp_machine_type,
               endpoint: gcp_cluster.endpoint,
               "clusters.name": gcp_cluster.gcp_cluster_name)

      next unless provider_gcp.count == 1

      correct_cluster_id = provider_gcp.first.cluster_id

      unless correct_cluster_id == platforms_kubernetes.cluster_id
        say 'Association mismatch detected'

        platforms_kubernetes.update(cluster_id: correct_cluster_id)
      end
    end
  end

  def down
    # noop
  end
end
