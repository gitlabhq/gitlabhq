# frozen_string_literal: true

module Clusters
  class Cluster < ApplicationRecord
    include Presentable
    include Gitlab::Utils::StrongMemoize
    include FromUnion
    include ReactiveCaching
    include AfterCommitQueue

    self.table_name = 'clusters'

    APPLICATIONS = {
      Applications::Helm.application_name => Applications::Helm,
      Applications::Ingress.application_name => Applications::Ingress,
      Applications::CertManager.application_name => Applications::CertManager,
      Applications::Crossplane.application_name => Applications::Crossplane,
      Applications::Prometheus.application_name => Applications::Prometheus,
      Applications::Runner.application_name => Applications::Runner,
      Applications::Jupyter.application_name => Applications::Jupyter,
      Applications::Knative.application_name => Applications::Knative,
      Applications::ElasticStack.application_name => Applications::ElasticStack
    }.freeze
    DEFAULT_ENVIRONMENT = '*'
    KUBE_INGRESS_BASE_DOMAIN = 'KUBE_INGRESS_BASE_DOMAIN'
    APPLICATIONS_ASSOCIATIONS = APPLICATIONS.values.map(&:association_name).freeze

    belongs_to :user
    belongs_to :management_project, class_name: '::Project', optional: true

    has_many :cluster_projects, class_name: 'Clusters::Project'
    has_many :projects, through: :cluster_projects, class_name: '::Project'
    has_one :cluster_project, -> { order(id: :desc) }, class_name: 'Clusters::Project'

    has_many :cluster_groups, class_name: 'Clusters::Group'
    has_many :groups, through: :cluster_groups, class_name: '::Group'

    # we force autosave to happen when we save `Cluster` model
    has_one :provider_gcp, class_name: 'Clusters::Providers::Gcp', autosave: true
    has_one :provider_aws, class_name: 'Clusters::Providers::Aws', autosave: true

    has_one :platform_kubernetes, class_name: 'Clusters::Platforms::Kubernetes', inverse_of: :cluster, autosave: true

    def self.has_one_cluster_application(name) # rubocop:disable Naming/PredicateName
      application = APPLICATIONS[name.to_s]
      has_one application.association_name, class_name: application.to_s, inverse_of: :cluster # rubocop:disable Rails/ReflectionClassName
    end

    has_one_cluster_application :helm
    has_one_cluster_application :ingress
    has_one_cluster_application :cert_manager
    has_one_cluster_application :crossplane
    has_one_cluster_application :prometheus
    has_one_cluster_application :runner
    has_one_cluster_application :jupyter
    has_one_cluster_application :knative
    has_one_cluster_application :elastic_stack

    has_many :kubernetes_namespaces

    accepts_nested_attributes_for :provider_gcp, update_only: true
    accepts_nested_attributes_for :provider_aws, update_only: true
    accepts_nested_attributes_for :platform_kubernetes, update_only: true

    validates :name, cluster_name: true
    validates :cluster_type, presence: true
    validates :domain, allow_blank: true, hostname: { allow_numeric_hostname: true }
    validates :namespace_per_environment, inclusion: { in: [true, false] }

    validate :restrict_modification, on: :update
    validate :no_groups, unless: :group_type?
    validate :no_projects, unless: :project_type?
    validate :unique_management_project_environment_scope

    after_save :clear_reactive_cache!

    delegate :status, to: :provider, allow_nil: true
    delegate :status_reason, to: :provider, allow_nil: true
    delegate :on_creation?, to: :provider, allow_nil: true
    delegate :knative_pre_installed?, to: :provider, allow_nil: true

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

    scope :managed, -> { where(managed: true) }
    scope :with_persisted_applications, -> { eager_load(*APPLICATIONS_ASSOCIATIONS) }
    scope :default_environment, -> { where(environment_scope: DEFAULT_ENVIRONMENT) }

    scope :for_project_namespace, -> (namespace_id) { joins(:projects).where(projects: { namespace_id: namespace_id }) }

    def self.ancestor_clusters_for_clusterable(clusterable, hierarchy_order: :asc)
      return [] if clusterable.is_a?(Instance)

      hierarchy_groups = clusterable.ancestors_upto(hierarchy_order: hierarchy_order).eager_load(:clusters)
      hierarchy_groups = hierarchy_groups.merge(current_scope) if current_scope

      hierarchy_groups.flat_map(&:clusters) + Instance.new.clusters
    end

    state_machine :cleanup_status, initial: :cleanup_not_started do
      state :cleanup_not_started, value: 1
      state :cleanup_uninstalling_applications, value: 2
      state :cleanup_removing_project_namespaces, value: 3
      state :cleanup_removing_service_account, value: 4
      state :cleanup_errored, value: 5

      event :start_cleanup do |cluster|
        transition [:cleanup_not_started, :cleanup_errored] => :cleanup_uninstalling_applications
      end

      event :continue_cleanup do
        transition(
          cleanup_uninstalling_applications: :cleanup_removing_project_namespaces,
          cleanup_removing_project_namespaces: :cleanup_removing_service_account)
      end

      event :make_cleanup_errored do
        transition any => :cleanup_errored
      end

      before_transition any => [:cleanup_errored] do |cluster, transition|
        status_reason = transition.args.first
        cluster.cleanup_status_reason = status_reason if status_reason
      end

      after_transition [:cleanup_not_started, :cleanup_errored] => :cleanup_uninstalling_applications do |cluster|
        cluster.run_after_commit do
          Clusters::Cleanup::AppWorker.perform_async(cluster.id)
        end
      end

      after_transition cleanup_uninstalling_applications: :cleanup_removing_project_namespaces do |cluster|
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

    def status_name
      return cleanup_status_name if cleanup_errored?
      return :cleanup_ongoing unless cleanup_not_started?

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

    def persisted_applications
      APPLICATIONS_ASSOCIATIONS.map(&method(:public_send)).compact
    end

    def applications
      APPLICATIONS_ASSOCIATIONS.map do |association_name|
        public_send(association_name) || public_send("build_#{association_name}") # rubocop:disable GitlabSecurity/PublicSend
      end
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
      platform_kubernetes.kubeclient if kubernetes?
    end

    def kubernetes_namespace_for(environment)
      project = environment.project
      persisted_namespace = Clusters::KubernetesNamespaceFinder.new(
        self,
        project: project,
        environment_name: environment.name
      ).execute

      persisted_namespace&.namespace || Gitlab::Kubernetes::DefaultNamespace.new(self, project: project).from_environment_slug(environment.slug)
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

    private

    def unique_management_project_environment_scope
      return unless management_project

      duplicate_management_clusters = management_project.management_clusters
        .where(environment_scope: environment_scope)
        .where.not(id: id)

      if duplicate_management_clusters.any?
        errors.add(:environment_scope, "cannot add duplicated environment scope")
      end
    end

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

Clusters::Cluster.prepend_if_ee('EE::Clusters::Cluster')
