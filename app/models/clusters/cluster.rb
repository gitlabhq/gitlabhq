# frozen_string_literal: true

module Clusters
  class Cluster < ApplicationRecord
    prepend HasEnvironmentScope
    include Presentable
    include Gitlab::Utils::StrongMemoize
    include FromUnion
    include ReactiveCaching
    include AfterCommitQueue

    self.table_name = 'clusters'

    DEFAULT_ENVIRONMENT = '*'
    KUBE_INGRESS_BASE_DOMAIN = 'KUBE_INGRESS_BASE_DOMAIN'

    self.reactive_cache_work_type = :external_dependency

    belongs_to :user
    belongs_to :management_project, class_name: '::Project', optional: true

    has_many :cluster_projects, class_name: 'Clusters::Project'
    has_many :projects, through: :cluster_projects, class_name: '::Project'
    has_one :cluster_project, -> { order(id: :desc) }, class_name: 'Clusters::Project'
    has_many :deployment_clusters
    has_many :deployments, inverse_of: :cluster, through: :deployment_clusters
    has_many :environments, -> { distinct }, through: :deployments

    has_many :cluster_groups, class_name: 'Clusters::Group'
    has_many :groups, through: :cluster_groups, class_name: '::Group'
    has_many :groups_projects, through: :groups, source: :projects, class_name: '::Project'

    # we force autosave to happen when we save `Cluster` model
    has_one :provider_gcp, class_name: 'Clusters::Providers::Gcp', autosave: true
    has_one :provider_aws, class_name: 'Clusters::Providers::Aws', autosave: true

    has_one :platform_kubernetes, class_name: 'Clusters::Platforms::Kubernetes', inverse_of: :cluster, autosave: true

    has_one :integration_prometheus, class_name: 'Clusters::Integrations::Prometheus', inverse_of: :cluster

    has_one :agent_migration, class_name: 'Clusters::AgentMigration', inverse_of: :cluster

    def self.has_one_cluster_application(name) # rubocop:disable Naming/PredicateName
      application = APPLICATIONS[name.to_s]
      has_one application.association_name, class_name: application.to_s, inverse_of: :cluster
    end

    has_many :kubernetes_namespaces

    accepts_nested_attributes_for :provider_gcp, update_only: true
    accepts_nested_attributes_for :provider_aws, update_only: true
    accepts_nested_attributes_for :platform_kubernetes, update_only: true

    validates :name, cluster_name: true
    validates :cluster_type, presence: true
    validates :domain, allow_blank: true, hostname: { allow_numeric_hostname: true }
    validates :namespace_per_environment, inclusion: { in: [true, false] }
    validates :helm_major_version, inclusion: { in: [2, 3] }

    attribute :helm_major_version, default: 3

    validate :restrict_modification, on: :update
    validate :no_groups, unless: :group_type?
    validate :no_projects, unless: :project_type?
    validate :unique_management_project_environment_scope
    validate :unique_environment_scope

    after_save :clear_reactive_cache!

    delegate :status, to: :provider, allow_nil: true
    delegate :status_reason, to: :provider, allow_nil: true

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
      gcp: 1,
      aws: 2
    }

    scope :enabled, -> { where(enabled: true) }
    scope :disabled, -> { where(enabled: false) }

    scope :user_provided, -> { where(provider_type: :user) }
    scope :gcp_provided, -> { where(provider_type: :gcp) }
    scope :aws_provided, -> { where(provider_type: :aws) }

    scope :gcp_installed, -> { gcp_provided.joins(:provider_gcp).merge(Clusters::Providers::Gcp.with_status(:created)) }
    scope :aws_installed, -> { aws_provided.joins(:provider_aws).merge(Clusters::Providers::Aws.with_status(:created)) }

    scope :distinct_with_deployed_environments, -> { joins(:environments).merge(::Deployment.success).distinct }

    scope :managed, -> { where(managed: true) }
    scope :default_environment, -> { where(environment_scope: DEFAULT_ENVIRONMENT) }
    scope :with_management_project, -> { where.not(management_project: nil) }

    scope :for_project_namespace, ->(namespace_id) { joins(:projects).where(projects: { namespace_id: namespace_id }) }
    scope :with_name, ->(name) { where(name: name) }

    scope :with_integration_prometheus, -> { includes(:integration_prometheus).joins(:integration_prometheus) }
    scope :with_project_http_integrations, ->(project_ids) do
      conditions = { projects: :alert_management_http_integrations }
      includes(conditions).joins(conditions).where(projects: { id: project_ids })
    end

    def self.ancestor_clusters_for_clusterable(clusterable, hierarchy_order: :asc)
      return [] if clusterable.is_a?(Instance)

      hierarchy_groups = clusterable.ancestors_upto(hierarchy_order: hierarchy_order).eager_load(:clusters)
      hierarchy_groups = hierarchy_groups.merge(current_scope) if current_scope

      hierarchy_groups.flat_map(&:clusters) + Instance.new.clusters
    end

    state_machine :cleanup_status, initial: :cleanup_not_started do
      state :cleanup_not_started, value: 1
      state :cleanup_removing_project_namespaces, value: 3
      state :cleanup_removing_service_account, value: 4
      state :cleanup_errored, value: 5

      event :start_cleanup do |cluster|
        transition [:cleanup_not_started, :cleanup_errored] => :cleanup_removing_project_namespaces
      end

      event :continue_cleanup do
        transition(
          cleanup_removing_project_namespaces: :cleanup_removing_service_account)
      end

      event :make_cleanup_errored do
        transition any => :cleanup_errored
      end

      before_transition any => [:cleanup_errored] do |cluster, transition|
        status_reason = transition.args.first
        cluster.cleanup_status_reason = status_reason if status_reason
      end

      after_transition [:cleanup_not_started, :cleanup_errored] => :cleanup_removing_project_namespaces do |cluster|
        cluster.run_after_commit do
          Clusters::Cleanup::ProjectNamespaceWorker.perform_async(cluster.id)
        end
      end

      after_transition cleanup_removing_project_namespaces: :cleanup_removing_service_account do |cluster|
        cluster.run_after_commit do
          Clusters::Cleanup::ServiceAccountWorker.perform_async(cluster.id)
        end
      end
    end

    def all_projects
      return projects if project_type?
      return groups_projects if group_type?

      ::Project.all
    end

    def status_name
      return cleanup_status_name if cleanup_errored?
      return :cleanup_ongoing unless cleanup_not_started?

      provider&.status_name || connection_status.presence || :created
    end

    def connection_error
      with_reactive_cache do |data|
        data[:connection_error]
      end
    end

    def node_connection_error
      with_reactive_cache do |data|
        data[:node_connection_error]
      end
    end

    def metrics_connection_error
      with_reactive_cache do |data|
        data[:metrics_connection_error]
      end
    end

    def connection_status
      with_reactive_cache do |data|
        data[:connection_status]
      end
    end

    def nodes
      with_reactive_cache do |data|
        data[:nodes]
      end
    end

    def calculate_reactive_cache
      return unless enabled?

      connection_data.merge(Gitlab::Kubernetes::Node.new(self).all)
    end

    def find_or_build_integration_prometheus
      integration_prometheus || build_integration_prometheus
    end

    def on_creation?
      !!provider&.on_creation?
    end

    def knative_pre_installed?
      !!provider&.knative_pre_installed?
    end

    def platform_kubernetes_active?
      !!platform_kubernetes&.active?
    end

    def platform_kubernetes_rbac?
      !!platform_kubernetes&.rbac?
    end

    def integration_prometheus_available?
      !!integration_prometheus&.available?
    end

    def provider
      if gcp?
        provider_gcp
      elsif aws?
        provider_aws
      end
    end

    def platform
      return platform_kubernetes if kubernetes?
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
      platform_kubernetes&.kubeclient if kubernetes?
    end

    def kubernetes_namespace_for(environment, deployable: environment.last_deployable)
      if deployable && environment.project_id != deployable.project_id
        raise ArgumentError, 'environment.project_id must match deployable.project_id'
      end

      managed_namespace(environment) ||
        ci_configured_namespace(deployable) ||
        default_namespace(environment)
    end

    def allow_user_defined_namespace?
      project_type? || !managed?
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

    def delete_cached_resources!
      kubernetes_namespaces.delete_all(:delete_all)
    end

    def clusterable
      return unless cluster_type

      case cluster_type
      when 'project_type'
        project
      when 'group_type'
        group
      when 'instance_type'
        instance
      else
        raise NotImplementedError
      end
    end

    def prometheus_adapter
      integration_prometheus
    end

    private

    def unique_management_project_environment_scope
      return unless management_project

      duplicate_management_clusters = management_project.management_clusters
        .where(environment_scope: environment_scope)
        .where.not(id: id)

      errors.add(:environment_scope, 'cannot add duplicated environment scope') if duplicate_management_clusters.any?
    end

    def unique_environment_scope
      if clusterable.present? && clusterable.clusters.where(environment_scope: environment_scope).where.not(id: id).exists?
        errors.add(:environment_scope, 'cannot add duplicated environment scope')
      end
    end

    def managed_namespace(environment)
      Clusters::KubernetesNamespaceFinder.new(
        self,
        project: environment.project,
        environment_name: environment.name
      ).execute&.namespace
    end

    def ci_configured_namespace(deployable)
      # YAML configuration of namespaces not supported for managed clusters
      return if managed?

      deployable&.expanded_kubernetes_namespace
    end

    def default_namespace(environment)
      Gitlab::Kubernetes::DefaultNamespace.new(
        self,
        project: environment.project
      ).from_environment_slug(environment.slug)
    end

    def instance_domain
      @instance_domain ||= Gitlab::CurrentSettings.auto_devops_domain
    end

    def connection_data
      result = ::Gitlab::Kubernetes::KubeClient.graceful_request(id) { kubeclient.core_client.discover }

      { connection_status: result[:status], connection_error: result[:connection_error] }.compact
    end

    # To keep backward compatibility with AUTO_DEVOPS_DOMAIN
    # environment variable, we need to ensure KUBE_INGRESS_BASE_DOMAIN
    # is set if AUTO_DEVOPS_DOMAIN is set on any of the following options:
    # ProjectAutoDevops#Domain, project variables or group variables,
    # as the AUTO_DEVOPS_DOMAIN is needed for CI_ENVIRONMENT_URL
    #
    # This method should is scheduled to be removed on
    # https://gitlab.com/gitlab-org/gitlab-foss/issues/56959
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
        errors.add(:base, _('Cannot modify provider during creation'))
        return false
      end

      true
    end

    def no_groups
      errors.add(:cluster, 'cannot have groups assigned') if groups.any?
    end

    def no_projects
      errors.add(:cluster, 'cannot have projects assigned') if projects.any?
    end
  end
end

Clusters::Cluster.prepend_mod_with('Clusters::Cluster')
