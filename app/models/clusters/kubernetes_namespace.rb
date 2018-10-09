# frozen_string_literal: true

module Clusters
  class KubernetesNamespace < ActiveRecord::Base
    self.table_name = 'clusters_kubernetes_namespaces'

    belongs_to :cluster_project, class_name: 'Clusters::Project'
    has_one :cluster, through: :cluster_project
    has_one :project, through: :cluster_project

    validates :namespace, presence: true
    before_validation :set_cluster_namespace_and_service_account
    before_validation :ensure_namespace_uniqueness

    attr_encrypted :encrypted_service_account_token,
        mode: :per_attribute_iv,
        key: Settings.attr_encrypted_db_key_base_truncated,
        algorithm: 'aes-256-cbc'

    private

    def set_cluster_namespace_and_service_account
      self.namespace = build_kubernetes_namespace
      self.service_account_name = build_service_account_name
    end

    def build_kubernetes_namespace
      gcp_kubernetes_namespace.presence || default_namespace
    end

    def build_service_account_name
      if cluster.platform_kubernetes_rbac?
        "#{default_service_account_name}-#{namespace}"
      else
        default_service_account_name
      end
    end

    def gcp_kubernetes_namespace
      @gcp_kubernetes_namespace ||= cluster&.platform_kubernetes&.namespace
    end

    def default_namespace
      project_slug.gsub(/[^-a-z0-9]/, '-').gsub(/^-+/, '')
    end

    def project_slug
      "#{project.path}-#{project.id}".downcase
    end

    def default_service_account_name
      Clusters::Gcp::Kubernetes::SERVICE_ACCOUNT_NAME
    end

    def ensure_namespace_uniqueness
      errors.add(:namespace, "Kubernetes namespace #{namespace} already exists on cluster") if kubernetes_namespace_exists?
    end

    def kubernetes_namespace_exists?
      cluster_project.kubernetes_namespaces.where(namespace: namespace).exists?
    end
  end
end
