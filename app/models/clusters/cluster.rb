# frozen_string_literal: true

module Clusters
  class Cluster < ApplicationRecord
    include Presentable
    include Gitlab::Utils::StrongMemoize
    include FromUnion
    include ReactiveCaching

    self.table_name = 'clusters'

    PROJECT_ONLY_APPLICATIONS = {
    }.freeze
    APPLICATIONS = {
      Applications::Helm.application_name => Applications::Helm,
      Applications::Ingress.application_name => Applications::Ingress,
      Applications::CertManager.application_name => Applications::CertManager,
      Applications::Prometheus.application_name => Applications::Prometheus,
      Applications::Runner.application_name => Applications::Runner,
      Applications::Jupyter.application_name => Applications::Jupyter,
      Applications::Knative.application_name => Applications::Knative
    }.merge(PROJECT_ONLY_APPLICATIONS).freeze
    DEFAULT_ENVIRONMENT = '*'
    KUBE_INGRESS_BASE_DOMAIN = 'KUBE_INGRESS_BASE_DOMAIN'

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
    has_one_cluster_application :prometheus
    has_one_cluster_application :runner
    has_one_cluster_application :jupyter
    has_one_cluster_application :knative

    has_many :kubernetes_namespaces

    accepts_nested_attributes_for :provider_gcp, update_only: true
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

    scope :default_environment, -> { where(environment_scope: DEFAULT_ENVIRONMENT) }

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
      APPLICATIONS.values.map do |application_class|
        public_send(application_class.association_name) || public_send("build_#{application_class.association_name}") # rubocop:disable GitlabSecurity/PublicSend
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

    def knative_pre_installed?
      provider&.knative_pre_installed?
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
