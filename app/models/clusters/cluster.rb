# frozen_string_literal: true

module Clusters
  class Cluster < ApplicationRecord
    include Presentable
    include Gitlab::Utils::StrongMemoize
    include FromUnion
    include ReactiveCaching

    self.table_name = 'clusters'

    PROJECT_ONLY_APPLICATIONS = {
      Applications::Jupyter.application_name => Applications::Jupyter,
      Applications::Knative.application_name => Applications::Knative
    }.freeze
    APPLICATIONS = {
      Applications::Helm.application_name => Applications::Helm,
      Applications::Ingress.application_name => Applications::Ingress,
      Applications::CertManager.application_name => Applications::CertManager,
      Applications::Runner.application_name => Applications::Runner,
      Applications::Prometheus.application_name => Applications::Prometheus
    }.merge(PROJECT_ONLY_APPLICATIONS).freeze
    DEFAULT_ENVIRONMENT = '*'.freeze
    KUBE_INGRESS_BASE_DOMAIN = 'KUBE_INGRESS_BASE_DOMAIN'.freeze

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

    accepts_nested_attributes_for :provider_gcp, update_only: true
    accepts_nested_attributes_for :platform_kubernetes, update_only: true

    validates :name, cluster_name: true
    validates :cluster_type, presence: true
    validates :domain, allow_blank: true, hostname: { allow_numeric_hostname: true }

    validate :restrict_modification, on: :update
    validate :no_groups, unless: :group_type?
    validate :no_projects, unless: :project_type?

    after_save :clear_reactive_cache!

    delegate :status, to: :provider, allow_nil: true
    delegate :status_reason, to: :provider, allow_nil: true
    delegate :on_creation?, to: :provider, allow_nil: true

    delegate :active?, to: :platform_kubernetes, prefix: true, allow_nil: true
    delegate :rbac?, to: :platform_kubernetes, prefix: true, allow_nil: true
    delegate :available?, to: :application_helm, prefix: true, allow_nil: true
    delegate :available?, to: :application_ingress, prefix: true, allow_nil: true
    delegate :available?, to: :application_prometheus, prefix: true, allow_nil: true
    delegate :available?, to: :application_knative, prefix: true, allow_nil: true
    delegate :external_ip, to: :application_ingress, prefix: true, allow_nil: true
    delegate :external_hostname, to: :application_ingress, prefix: true, allow_nil: true

    alias_attribute :base_domain, :domain
    alias_attribute :provided_by_user?, :user?

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
    scope :managed, -> { where(managed: true) }

    scope :default_environment, -> { where(environment_scope: DEFAULT_ENVIRONMENT) }

    scope :missing_kubernetes_namespace, -> (kubernetes_namespaces) do
      subquery = kubernetes_namespaces.select('1').where('clusters_kubernetes_namespaces.cluster_id = clusters.id')

      where('NOT EXISTS (?)', subquery)
    end

    scope :with_knative_installed, -> { joins(:application_knative).merge(Clusters::Applications::Knative.available) }

    scope :preload_knative, -> {
      preload(
        :kubernetes_namespaces,
        :platform_kubernetes,
        :application_knative
      )
    }

    def self.ancestor_clusters_for_clusterable(clusterable, hierarchy_order: :asc)
      return [] if clusterable.is_a?(Instance)

      hierarchy_groups = clusterable.ancestors_upto(hierarchy_order: hierarchy_order).eager_load(:clusters)
      hierarchy_groups = hierarchy_groups.merge(current_scope) if current_scope

      hierarchy_groups.flat_map(&:clusters) + Instance.new.clusters
    end

    def status_name
      provider&.status_name || connection_status.presence || :created
    end

    def connection_status
      with_reactive_cache do |data|
        data[:connection_status]
      end
    end

    def calculate_reactive_cache
      return unless enabled?

      { connection_status: retrieve_connection_status }
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

    def instance
      Instance.new if instance_type?
    end

    def kubeclient
      platform_kubernetes.kubeclient if kubernetes?
    end

    def kubernetes_namespace_for(project)
      find_or_initialize_kubernetes_namespace_for_project(project).namespace
    end

    def find_or_initialize_kubernetes_namespace_for_project(project)
      attributes = { project: project }
      attributes[:cluster_project] = cluster_project if project_type?

      kubernetes_namespaces.find_or_initialize_by(attributes).tap do |namespace|
        namespace.set_defaults
      end
    end

    def allow_user_defined_namespace?
      project_type?
    end

    def kube_ingress_domain
      @kube_ingress_domain ||= domain.presence || instance_domain
    end

    def predefined_variables
      Gitlab::Ci::Variables::Collection.new.tap do |variables|
        break variables unless kube_ingress_domain

        variables.append(key: KUBE_INGRESS_BASE_DOMAIN, value: kube_ingress_domain)
      end
    end

    def knative_services_finder(project)
      @knative_services_finder ||= KnativeServicesFinder.new(self, project)
    end

    private

    def instance_domain
      @instance_domain ||= Gitlab::CurrentSettings.auto_devops_domain
    end

    def retrieve_connection_status
      kubeclient.core_client.discover
    rescue *Gitlab::Kubernetes::Errors::CONNECTION
      :unreachable
    rescue *Gitlab::Kubernetes::Errors::AUTHENTICATION
      :authentication_failure
    rescue Kubeclient::HttpError => e
      kubeclient_error_status(e.message)
    rescue => e
      Gitlab::Sentry.track_acceptable_exception(e, extra: { cluster_id: id })

      :unknown_failure
    else
      :connected
    end

    # KubeClient uses the same error class
    # For connection errors (eg. timeout) and
    # for Kubernetes errors.
    def kubeclient_error_status(message)
      if message&.match?(/timed out|timeout/i)
        :unreachable
      else
        :authentication_failure
      end
    end

    # To keep backward compatibility with AUTO_DEVOPS_DOMAIN
    # environment variable, we need to ensure KUBE_INGRESS_BASE_DOMAIN
    # is set if AUTO_DEVOPS_DOMAIN is set on any of the following options:
    # ProjectAutoDevops#Domain, project variables or group variables,
    # as the AUTO_DEVOPS_DOMAIN is needed for CI_ENVIRONMENT_URL
    #
    # This method should is scheduled to be removed on
    # https://gitlab.com/gitlab-org/gitlab-ce/issues/56959
    def legacy_auto_devops_domain
      if project_type?
        project&.auto_devops&.domain.presence ||
          project.variables.find_by(key: 'AUTO_DEVOPS_DOMAIN')&.value.presence ||
          project.group&.variables&.find_by(key: 'AUTO_DEVOPS_DOMAIN')&.value.presence
      elsif group_type?
        group.variables.find_by(key: 'AUTO_DEVOPS_DOMAIN')&.value.presence
      end
    end

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
