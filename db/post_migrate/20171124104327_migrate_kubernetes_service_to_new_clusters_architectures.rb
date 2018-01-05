class MigrateKubernetesServiceToNewClustersArchitectures < ActiveRecord::Migration
  DOWNTIME = false
  DEFAULT_KUBERNETES_SERVICE_CLUSTER_NAME = 'KubernetesService'.freeze

  class Project < ActiveRecord::Base
    self.table_name = 'projects'

    has_many :cluster_projects, class_name: 'MigrateKubernetesServiceToNewClustersArchitectures::ClustersProject'
    has_many :clusters, through: :cluster_projects, class_name: 'MigrateKubernetesServiceToNewClustersArchitectures::Cluster'
    has_many :services, class_name: 'MigrateKubernetesServiceToNewClustersArchitectures::Service'
  end

  class Cluster < ActiveRecord::Base
    self.table_name = 'clusters'

    has_many :cluster_projects, class_name: 'MigrateKubernetesServiceToNewClustersArchitectures::ClustersProject'
    has_many :projects, through: :cluster_projects, class_name: 'MigrateKubernetesServiceToNewClustersArchitectures::Project'
    has_one :platform_kubernetes, class_name: 'MigrateKubernetesServiceToNewClustersArchitectures::PlatformsKubernetes'

    accepts_nested_attributes_for :platform_kubernetes

    enum platform_type: {
      kubernetes: 1
    }

    enum provider_type: {
      user: 0,
      gcp: 1
    }
  end

  class ClustersProject < ActiveRecord::Base
    self.table_name = 'cluster_projects'

    belongs_to :cluster, class_name: 'MigrateKubernetesServiceToNewClustersArchitectures::Cluster'
    belongs_to :project, class_name: 'MigrateKubernetesServiceToNewClustersArchitectures::Project'
  end

  class PlatformsKubernetes < ActiveRecord::Base
    self.table_name = 'cluster_platforms_kubernetes'

    belongs_to :cluster, class_name: 'MigrateKubernetesServiceToNewClustersArchitectures::Cluster'

    attr_encrypted :token,
      mode: :per_attribute_iv,
      key: Gitlab::Application.secrets.db_key_base,
      algorithm: 'aes-256-cbc'
  end

  class Service < ActiveRecord::Base
    include EachBatch

    self.table_name = 'services'

    belongs_to :project, class_name: 'MigrateKubernetesServiceToNewClustersArchitectures::Project'

    scope :unmanaged_kubernetes_service, -> do
      where(category: 'deployment')
      .where(type: 'KubernetesService')
      .where(template: false)
      .where("NOT EXISTS (?)",
        MigrateKubernetesServiceToNewClustersArchitectures::PlatformsKubernetes
          .joins('INNER JOIN projects ON projects.id = services.project_id')
          .joins('INNER JOIN cluster_projects ON cluster_projects.project_id = projects.id')
          .where('cluster_projects.cluster_id = cluster_platforms_kubernetes.cluster_id')
          .where("services.properties LIKE CONCAT('%', cluster_platforms_kubernetes.api_url, '%')")
          .select('1') )
      .order(project_id: :asc)
    end

    scope :kubernetes_service_without_template, -> do
      where(category: 'deployment')
      .where(type: 'KubernetesService')
      .where(template: false)
      .order(project_id: :asc)
    end
  end

  def find_dedicated_environement_scope(project)
    environment_scopes = project.clusters.map(&:environment_scope)

    return '*' if environment_scopes.exclude?('*') # KubernetesService should be added as a default cluster (environment_scope: '*') at first place
    return 'migrated/*' if environment_scopes.exclude?('migrated/*') # If it's conflicted, the KubernetesService added as a migrated cluster

    unique_iid = 0

    # If it's still conflicted, finding an unique environment scope incrementaly
    loop do
      candidate = "migrated#{unique_iid}/*"
      return candidate if environment_scopes.exclude?(candidate)

      unique_iid += 1
    end
  end

  def up
    MigrateKubernetesServiceToNewClustersArchitectures::Service
      .unmanaged_kubernetes_service.each_batch(of: 100) do |kubernetes_services|

      rows_for_clusters = kubernetes_services.map do |kubernetes_service|
        {
          enabled: kubernetes_service.active,
          user_id: nil, # KubernetesService doesn't have
          name: DEFAULT_KUBERNETES_SERVICE_CLUSTER_NAME,
          provider_type: MigrateKubernetesServiceToNewClustersArchitectures::Cluster.provider_types[:user],
          platform_type: MigrateKubernetesServiceToNewClustersArchitectures::Cluster.platform_types[:kubernetes],
          environment_scope: find_dedicated_environement_scope(kubernetes_service.project),
          created_at: Gitlab::Database.sanitize_timestamp(kubernetes_service.created_at),
          updated_at: Gitlab::Database.sanitize_timestamp(kubernetes_service.updated_at)
        }
      end

      inserted_cluster_ids = Gitlab::Database.bulk_insert('clusters', rows_for_clusters, return_ids: true)

      rows_for_cluster_platforms_kubernetes = kubernetes_services.each_with_index.map do |kubernetes_service, i|

        # Create PlatformsKubernetes instance for generating an encrypted token
        platforms_kubernetes =
          MigrateKubernetesServiceToNewClustersArchitectures::PlatformsKubernetes
          .new(token: kubernetes_service.token)

        {
          cluster_id: inserted_cluster_ids[i],
          api_url: kubernetes_service.api_url,
          ca_cert: kubernetes_service.ca_pem,
          namespace: kubernetes_service.namespace,
          username: nil, # KubernetesService doesn't have
          encrypted_password: nil, # KubernetesService doesn't have
          encrypted_password_iv: nil, # KubernetesService doesn't have
          encrypted_token: platforms_kubernetes.encrypted_token, # encrypted_token and encrypted_token_iv
          encrypted_token_iv: platforms_kubernetes.encrypted_token_iv, # encrypted_token and encrypted_token_iv
          created_at: Gitlab::Database.sanitize_timestamp(kubernetes_service.created_at),
          updated_at: Gitlab::Database.sanitize_timestamp(kubernetes_service.updated_at)
        }
      end

      Gitlab::Database.bulk_insert('cluster_platforms_kubernetes', rows_for_cluster_platforms_kubernetes)

      rows_for_cluster_projects = kubernetes_services.each_with_index.map do |kubernetes_service, i|
        {
          cluster_id: inserted_cluster_ids[i],
          project_id: kubernetes_service.project_id,
          created_at: Gitlab::Database.sanitize_timestamp(kubernetes_service.created_at),
          updated_at: Gitlab::Database.sanitize_timestamp(kubernetes_service.updated_at)
        }
      end

      Gitlab::Database.bulk_insert('cluster_projects', rows_for_cluster_projects)
    end

    MigrateKubernetesServiceToNewClustersArchitectures::Service.kubernetes_service_without_template.update_all(active: false)
  end

  def down
    # noop
  end
end
