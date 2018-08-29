# frozen_string_literal: true

module Clusters
  module Gcp
    module Kubernetes
      class CreateServiceAccountService
        attr_reader :api_url, :ca_pem, :username, :password

        def initialize(api_url, ca_pem, username, password)
          @api_url = api_url
          @ca_pem = ca_pem
          @username = username
          @password = password
        end

        def execute
          kubeclient = build_kube_client!(api_groups: ['api', 'apis/rbac.authorization.k8s.io'])

          kubeclient.create_service_account(service_account_resource)
          kubeclient.create_cluster_role_binding(cluster_role_binding_resource)
        end

        private

        def service_account_resource
          Gitlab::Kubernetes::ServiceAccount.new(SERVICE_ACCOUNT_NAME, 'default').generate
        end

        def cluster_role_binding_resource
          subjects = [{ kind: 'ServiceAccount', name: SERVICE_ACCOUNT_NAME, namespace: 'default' }]

          Gitlab::Kubernetes::ClusterRoleBinding.new(
            CLUSTER_ROLE_BINDING_NAME,
            CLUSTER_ROLE_NAME,
            subjects
          ).generate
        end

        def build_kube_client!(api_groups: ['api'], api_version: 'v1')
          raise "Incomplete settings" unless api_url && username && password

          Gitlab::Kubernetes::KubeClient.new(
            api_url,
            api_groups,
            api_version,
            auth_options: { username: username, password: password },
            ssl_options: kubeclient_ssl_options,
            http_proxy_uri: ENV['http_proxy']
          )
        end

        def kubeclient_ssl_options
          opts = { verify_ssl: OpenSSL::SSL::VERIFY_PEER }

          if ca_pem.present?
            opts[:cert_store] = OpenSSL::X509::Store.new
            opts[:cert_store].add_cert(OpenSSL::X509::Certificate.new(ca_pem))
          end

          opts
        end
      end
    end
  end
end
