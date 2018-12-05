# frozen_string_literal: true

module Clusters
  class Cluster < ActiveRecord::Base
    include Presentable
    include Gitlab::Utils::StrongMemoize
    include FromUnion

    self.table_name = 'clusters'

    APPLICATIONS = {
      Applications::Helm.application_name => Applications::Helm,
      Applications::Ingress.application_name => Applications::Ingress,
      Applications::CertManager.application_name => Applications::CertManager,
      Applications::Prometheus.application_name => Applications::Prometheus,
      Applications::Runner.application_name => Applications::Runner,
      Applications::Jupyter.application_name => Applications::Jupyter,
      Applications::Knative.application_name => Applications::Knative
    }.freeze
    DEFAULT_ENVIRONMENT = '*'.freeze

    belongs_to :user

    has_many :cluster_projects, class_name: 'Clusters::Project'
    has_many :projects, through: :cluster_projects, class_name: '::Project'
    has_one :cluster_project, -> { order(id: :desc) }, class_name: 'Clusters::Project'

    has_many :cluster_groups, class_name: 'Clusters::Group'
    has_many :groups, through: :cluster_groups, class_name: '::Group'

    # we force autosave to happen when we save `Cluster` model
    has_one :provider_gcp, class_name: 'Clusters::Providers::Gcp', autosave: true

    has_one :platform_kubernetes, class_name: 'Clusters::Platforms::Kubernetes', inverse_of: :cluster, autosave: true

    has_one :application_helm, class_name: 'Clusters::Applications::Helm'
    has_one :application_ingress, class_name: 'Clusters::Applications::Ingress'
    has_one :application_cert_manager, class_name: 'Clusters::Applications::CertManager'
    has_one :application_prometheus, class_name: 'Clusters::Applications::Prometheus'
    has_one :application_runner, class_name: 'Clusters::Applications::Runner'
    has_one :application_jupyter, class_name: 'Clusters::Applications::Jupyter'
    has_one :application_knative, class_name: 'Clusters::Applications::Knative'

    has_many :kubernetes_namespaces
    has_one :kubernetes_namespace, -> { order(id: :desc) }, class_name: 'Clusters::KubernetesNamespace'

    accepts_nested_attributes_for :provider_gcp, update_only: true
    accepts_nested_attributes_for :platform_kubernetes, update_only: true

    validates :name, cluster_name: true
    validates :cluster_type, presence: true
    validate :restrict_modification, on: :update

    validate :no_groups, unless: :group_type?
    validate :no_projects, unless: :project_type?

    delegate :status, to: :provider, allow_nil: true
    delegate :status_reason, to: :provider, allow_nil: true
    delegate :on_creation?, to: :provider, allow_nil: true

    delegate :active?, to: :platform_kubernetes, prefix: true, allow_nil: true
    delegate :rbac?, to: :platform_kubernetes, prefix: true, allow_nil: true
    delegate :available?, to: :application_helm, prefix: true, allow_nil: true
    delegate :available?, to: :application_ingress, prefix: true, allow_nil: true
    delegate :available?, to: :application_prometheus, prefix: true, allow_nil: true

    enum cluster_type: {
      instance_type: 1,
      group_type: 2,
      project_type: 3
    }

    enum platform_type: {
      kubernetes: 1
    }

    enum provider_type: {
      user: 0,
      gcp: 1
    }

    scope :enabled, -> { where(enabled: true) }
    scope :disabled, -> { where(enabled: false) }
    scope :user_provided, -> { where(provider_type: ::Clusters::Cluster.provider_types[:user]) }
    scope :gcp_provided, -> { where(provider_type: ::Clusters::Cluster.provider_types[:gcp]) }
    scope :gcp_installed, -> { gcp_provided.includes(:provider_gcp).where(cluster_providers_gcp: { status: ::Clusters::Providers::Gcp.state_machines[:status].states[:created].value }) }

    scope :default_environment, -> { where(environment_scope: DEFAULT_ENVIRONMENT) }

    scope :missing_kubernetes_namespace, -> (kubernetes_namespaces) do
      subquery = kubernetes_namespaces.select('1').where('clusters_kubernetes_namespaces.cluster_id = clusters.id')

      where('NOT EXISTS (?)', subquery)
    end

    def self.ancestor_clusters_for_clusterable(clusterable, hierarchy_order: :asc)
      hierarchy_groups = clusterable.ancestors_upto(hierarchy_order: hierarchy_order).eager_load(:clusters)
      hierarchy_groups = hierarchy_groups.merge(current_scope) if current_scope

      hierarchy_groups.flat_map(&:clusters)
    end

    def status_name
      if provider
        provider.status_name
      else
        :created
      end
    end

    def created?
      status_name == :created
    end

    def applications
      [
        application_helm || build_application_helm,
        application_ingress || build_application_ingress,
        application_cert_manager || build_application_cert_manager,
        application_prometheus || build_application_prometheus,
        application_runner || build_application_runner,
        application_jupyter || build_application_jupyter,
        application_knative || build_application_knative
      ]
    end

    def provider
      return provider_gcp if gcp?
    end

    def platform
      return platform_kubernetes if kubernetes?
    end

    def managed?
      !user?
    end

    def all_projects
      if project_type?
        projects
      elsif group_type?
        first_group.all_projects
      else
        Project.none
      end
    end

    def first_project
      strong_memoize(:first_project) do
        projects.first
      end
    end
    alias_method :project, :first_project

    def first_group
      strong_memoize(:first_group) do
        groups.first
      end
    end
    alias_method :group, :first_group

    def kubeclient
      platform_kubernetes.kubeclient if kubernetes?
    end

    def find_or_initialize_kubernetes_namespace_for_project(project)
      if project_type?
        kubernetes_namespaces.find_or_initialize_by(
          project: project,
          cluster_project: cluster_project
        )
      else
        kubernetes_namespaces.find_or_initialize_by(
          project: project
        )
      end
    end

    def allow_user_defined_namespace?
      project_type?
    end

    private

    def restrict_modification
      if provider&.on_creation?
        errors.add(:base, "cannot modify during creation")
        return false
      end

      true
    end

    def no_groups
      if groups.any?
        errors.add(:cluster, 'cannot have groups assigned')
      end
    end

    def no_projects
      if projects.any?
        errors.add(:cluster, 'cannot have projects assigned')
      end
    end
  end
end
