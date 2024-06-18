# frozen_string_literal: true

module Clusters
  class KubernetesNamespace < ApplicationRecord
    include Gitlab::Kubernetes

    self.table_name = 'clusters_kubernetes_namespaces'

    belongs_to :cluster_project, class_name: 'Clusters::Project'
    belongs_to :cluster, class_name: 'Clusters::Cluster'
    belongs_to :project, class_name: '::Project'
    belongs_to :environment, optional: true
    has_one :platform_kubernetes, through: :cluster

    validates :namespace, presence: true
    validates :namespace, uniqueness: { scope: :cluster_id }
    validates :environment_id, uniqueness: { scope: [:cluster_id, :project_id] }, allow_nil: true

    validates :service_account_name, presence: true

    delegate :ca_pem, to: :platform_kubernetes, allow_nil: true
    delegate :api_url, to: :platform_kubernetes, allow_nil: true

    attr_encrypted :service_account_token,
      mode: :per_attribute_iv,
      key: Settings.attr_encrypted_db_key_base_truncated,
      algorithm: 'aes-256-cbc'

    scope :has_service_account_token, -> { where.not(encrypted_service_account_token: nil) }
    scope :with_environment_name, ->(name) { joins(:environment).where(environments: { name: name }) }

    def token_name
      "#{namespace}-token"
    end

    def predefined_variables
      Gitlab::Ci::Variables::Collection.new.tap do |variables|
        variables
          .append(key: 'KUBE_SERVICE_ACCOUNT', value: service_account_name.to_s)
          .append(key: 'KUBE_NAMESPACE', value: namespace.to_s)
          .append(key: 'KUBE_TOKEN', value: service_account_token.to_s, public: false, masked: true)
          .append(key: 'KUBECONFIG', value: kubeconfig, public: false, file: true)
      end
    end

    private

    def kubeconfig
      to_kubeconfig(
        url: api_url,
        namespace: namespace,
        token: service_account_token,
        ca_pem: ca_pem)
    end
  end
end
