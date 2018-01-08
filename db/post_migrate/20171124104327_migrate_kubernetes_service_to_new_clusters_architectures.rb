class MigrateKubernetesServiceToNewClustersArchitectures < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  DEFAULT_KUBERNETES_SERVICE_CLUSTER_NAME = 'KubernetesService'.freeze

  disable_ddl_transaction!

  class Project < ActiveRecord::Base
    self.table_name = 'projects'

    has_many :cluster_projects, class_name: 'MigrateKubernetesServiceToNewClustersArchitectures::ClustersProject'
    has_many :clusters, through: :cluster_projects, class_name: 'MigrateKubernetesServiceToNewClustersArchitectures::Cluster'
    has_many :services, class_name: 'MigrateKubernetesServiceToNewClustersArchitectures::Service'
    has_one :kubernetes_service, -> { where(category: 'deployment', type: 'KubernetesService') }, class_name: 'MigrateKubernetesServiceToNewClustersArchitectures::Service', inverse_of: :project, foreign_key: :project_id
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
    self.inheritance_column = :_type_disabled # Disable STI, otherwise KubernetesModel will be looked up

    belongs_to :project, class_name: 'MigrateKubernetesServiceToNewClustersArchitectures::Project', foreign_key: :project_id

    scope :unmanaged_kubernetes_service, -> do
      joins('LEFT JOIN projects ON projects.id = services.project_id')
      .joins('LEFT JOIN cluster_projects ON cluster_projects.project_id = projects.id')
      .joins('LEFT JOIN cluster_platforms_kubernetes ON cluster_platforms_kubernetes.cluster_id = cluster_projects.cluster_id')
      .where(category: 'deployment', type: 'KubernetesService', template: false)
      .where("services.properties LIKE '%api_url%'")
      .where("(services.properties NOT LIKE CONCAT('%', cluster_platforms_kubernetes.api_url, '%')) OR cluster_platforms_kubernetes.api_url IS NULL")
      .group(:id)
      .order(id: :asc)
    end

    scope :kubernetes_service_without_template, -> do
      where(category: 'deployment', type: 'KubernetesService', template: false)
    end

    def api_url
      parsed_properties['api_url']
    end

    def ca_pem
      parsed_properties['ca_pem']
    end

    def namespace
      parsed_properties['namespace']
    end

    def token
      parsed_properties['token']
    end

    private

    def parsed_properties
      @parsed_properties ||= JSON.parse(self.properties)
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
    ActiveRecord::Base.transaction do
      MigrateKubernetesServiceToNewClustersArchitectures::Service
        .unmanaged_kubernetes_service.find_each(batch_size: 1) do |kubernetes_service|
        MigrateKubernetesServiceToNewClustersArchitectures::Cluster.create(
          enabled: kubernetes_service.active,
          user_id: nil, # KubernetesService doesn't have
          name: DEFAULT_KUBERNETES_SERVICE_CLUSTER_NAME,
          provider_type: MigrateKubernetesServiceToNewClustersArchitectures::Cluster.provider_types[:user],
          platform_type: MigrateKubernetesServiceToNewClustersArchitectures::Cluster.platform_types[:kubernetes],
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
    end

    MigrateKubernetesServiceToNewClustersArchitectures::Service
      .kubernetes_service_without_template.each_batch(of: 100) do |kubernetes_service|
      kubernetes_service.update_all(active: false)
    end
  end

  def down
    # noop
  end
end
