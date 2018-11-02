# frozen_string_literal: true

module Clusters
  class KubernetesNamespace < ActiveRecord::Base
    include Gitlab::Kubernetes

    self.table_name = 'clusters_kubernetes_namespaces'

    belongs_to :cluster_project, class_name: 'Clusters::Project'
    belongs_to :cluster, class_name: 'Clusters::Cluster'
    belongs_to :project, class_name: '::Project'
    has_one :platform_kubernetes, through: :cluster

    validates :namespace, presence: true
    validates :namespace, uniqueness: { scope: :cluster_id }

    delegate :ca_pem, to: :platform_kubernetes, allow_nil: true
    delegate :api_url, to: :platform_kubernetes, allow_nil: true

    attr_encrypted :service_account_token,
        mode: :per_attribute_iv,
        key: Settings.attr_encrypted_db_key_base_truncated,
        algorithm: 'aes-256-cbc'

    def token_name
      "#{namespace}-token"
    end

    def configure_predefined_credentials
      self.namespace = kubernetes_or_project_namespace
      self.service_account_name = default_service_account_name
    end

    def predefined_variables
      config = YAML.dump(kubeconfig)

      Gitlab::Ci::Variables::Collection.new.tap do |variables|
        variables
          .append(key: 'KUBE_SERVICE_ACCOUNT', value: service_account_name)
          .append(key: 'KUBE_NAMESPACE', value: namespace)
          .append(key: 'KUBE_TOKEN', value: service_account_token, public: false)
          .append(key: 'KUBECONFIG', value: config, public: false, file: true)
      end
    end

    private

    def kubernetes_or_project_namespace
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

    def kubeconfig
      to_kubeconfig(
        url: api_url,
        namespace: namespace,
        token: service_account_token,
        ca_pem: ca_pem)
    end
  end
end
