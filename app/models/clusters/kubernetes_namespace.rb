# frozen_string_literal: true

module Clusters
  class KubernetesNamespace < ActiveRecord::Base
    self.table_name = 'clusters_kubernetes_namespaces'

    belongs_to :cluster_project, class_name: 'Clusters::Project'
    has_one :cluster, through: :cluster_project
    has_one :project, through: :cluster_project

    delegate :platform_kubernetes, to: :cluster, allow_nil: true
    delegate :rbac?, to: :platform_kubernetes, prefix: true, allow_nil: true

    validates :namespace, presence: true
    validates :namespace, uniqueness: { scope: :cluster_project_id }

    before_validation :set_cluster_namespace_and_service_account

    attr_encrypted :service_account_token,
        mode: :per_attribute_iv,
        key: Settings.attr_encrypted_db_key_base_truncated,
        algorithm: 'aes-256-cbc'

    def token_name
      "#{namespace}-token"
    end

    private

    def set_cluster_namespace_and_service_account
      self.namespace = build_kubernetes_namespace
      self.service_account_name = build_service_account_name
    end

    def build_kubernetes_namespace
      platform_kubernetes_namespace.presence || default_namespace
    end

    def build_service_account_name
      "#{namespace}-service-account"
    end

    def platform_kubernetes_namespace
      @platform_kubernetes_namespace ||= platform_kubernetes&.namespace
    end

    def default_namespace
      project_slug.gsub(/[^-a-z0-9]/, '-').gsub(/^-+/, '')
    end

    def project_slug
      "#{project.path}-#{project.id}".downcase
    end
  end
end
