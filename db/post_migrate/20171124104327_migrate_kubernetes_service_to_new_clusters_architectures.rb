class MigrateKubernetesServiceToNewClustersArchitectures < ActiveRecord::Migration
  DOWNTIME = false
  DEFAULT_KUBERNETES_SERVICE_CLUSTER_NAME = 'KubernetesService'.freeze

  class Project < ActiveRecord::Base
    self.table_name = 'projects'

    has_many :cluster_projects, class_name: 'ClustersProject'
    has_many :clusters, through: :cluster_projects, class_name: 'Cluster'
  end

  class Cluster < ActiveRecord::Base
    self.table_name = 'clusters'

    has_many :cluster_projects, class_name: 'ClustersProject'
    has_many :projects, through: :cluster_projects, class_name: 'Project'
    has_one :platform_kubernetes, class_name: 'PlatformsKubernetes'

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

    belongs_to :cluster, class_name: 'Cluster'
    belongs_to :project, class_name: 'Project'
  end

  class PlatformsKubernetes < ActiveRecord::Base
    self.table_name = 'cluster_platforms_kubernetes'

    attr_encrypted :token,
      mode: :per_attribute_iv,
      key: Gitlab::Application.secrets.db_key_base,
      algorithm: 'aes-256-cbc'
  end

  class Service < ActiveRecord::Base
    include EachBatch

    self.table_name = 'services'

    belongs_to :project, class_name: 'Project'

    scope :kubernetes_service, -> do
      where("services.category = 'deployment'")
      .where("services.type = 'KubernetesService'")
      .where("services.template = FALSE")
      .order('services.project_id')
    end
  end

  def find_dedicated_environement_scope(project)
    environment_scopes = project.clusters.map(&:environment_scope)

    return '*' if environment_scopes.exclude?('*') # KubernetesService should be added as a default cluster (environment_scope: '*') at first place
    return 'migrated/*' if environment_scopes.exclude?('migrated/*') # If it's conflicted, the KubernetesService added as a migrated cluster

    unique_iid = 0

    # If it's still conflicted, finding an unique environment scope incrementaly
    while true
      candidate = "migrated#{unique_iid}/*"
      return candidate if environment_scopes.exclude?(candidate)
      unique_iid += 1
    end
  end

  # KubernetesService might be already managed by clusters
  def managed_by_clusters?(kubernetes_service)
    kubernetes_service.project.clusters
      .joins('INNER JOIN cluster_platforms_kubernetes ON clusters.id = cluster_platforms_kubernetes.cluster_id')
      .where('cluster_platforms_kubernetes.api_url = ?', kubernetes_service.api_url)
      .exists?
  end

  def up
    Service.kubernetes_service.find_each(batch_size: 1) do |kubernetes_service|
      unless managed_by_clusters?(kubernetes_service)
        Cluster.create(
          enabled: kubernetes_service.active,
          user_id: nil, # KubernetesService doesn't have
          name: DEFAULT_KUBERNETES_SERVICE_CLUSTER_NAME,
          provider_type: Cluster.provider_types[:user],
          platform_type: Cluster.platform_types[:kubernetes],
          projects: [kubernetes_service.project],
          environment_scope: find_dedicated_environement_scope(kubernetes_service.project),
          platform_kubernetes_attributes: {
            api_url: kubernetes_service.api_url,
            ca_cert: kubernetes_service.ca_pem,
            namespace: kubernetes_service.namespace,
            username: nil, # KubernetesService doesn't have
            encrypted_password: nil, # KubernetesService doesn't have
            encrypted_password_iv: nil, # KubernetesService doesn't have
            token: kubernetes_service.token # encrypted_token and encrypted_token_iv
          } )
      end

      # Disable the KubernetesService. Platforms::Kubernetes will be used from next time.
      kubernetes_service.active = false
      kubernetes_service.properties.merge!( { migrated: true } )
      kubernetes_service.save!
    end
  end

  def down
    # noop
  end
end
