# frozen_string_literal: true

module Clusters
  class KubernetesNamespace < ActiveRecord::Base
    self.table_name = 'clusters_kubernetes_namespaces'

    belongs_to :cluster_project, class_name: 'Clusters::Project'
    belongs_to :cluster, class_name: 'Clusters::Cluster'
    belongs_to :project, class_name: '::Project'
    has_one :platform_kubernetes, through: :cluster

    validates :namespace, presence: true
    validates :namespace, uniqueness: { scope: :cluster_id }

    before_validation :set_namespace_and_service_account_to_default, on: :create

    attr_encrypted :service_account_token,
        mode: :per_attribute_iv,
        key: Settings.attr_encrypted_db_key_base_truncated,
        algorithm: 'aes-256-cbc'

    def token_name
      "#{namespace}-token"
    end

    private

    def set_namespace_and_service_account_to_default
      self.namespace ||= default_namespace
      self.service_account_name ||= default_service_account_name
    end

    def default_namespace
      platform_kubernetes&.namespace.presence || project_namespace
    end

    def default_service_account_name
      "#{namespace}-service-account"
    end

    def project_namespace
      Gitlab::NamespaceSanitizer.sanitize(project_slug)
    end

    def project_slug
      "#{project.path}-#{project.id}".downcase
    end
  end
end
