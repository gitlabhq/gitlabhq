# frozen_string_literal: true

require 'securerandom'
require 'mkmf'
require 'pathname'

module QA
  module Service
    class KubernetesCluster
      include Service::Shellout

      attr_reader :api_url, :ca_certificate, :token, :rbac, :provider

      def initialize(rbac: true, provider_class: QA::Service::ClusterProvider::Gcloud)
        @rbac = rbac
        @provider = provider_class.new(rbac: rbac)
      end

      def create!
        validate_dependencies

        @provider.validate_dependencies
        @provider.setup

        @api_url = fetch_api_url

        credentials = @provider.filter_credentials(fetch_credentials)
        @ca_certificate = Base64.decode64(credentials.dig('data', 'ca.crt'))
        @token = Base64.decode64(credentials.dig('data', 'token'))

        self
      end

      def remove!
        @provider.teardown
      end

      def cluster_name
        @provider.cluster_name
      end

      def to_s
        cluster_name
      end

      def create_secret(secret, secret_name)
        shell("kubectl create secret generic #{secret_name} --from-literal=token='#{secret}'")
      end

      def apply_manifest(manifest)
        shell('kubectl apply -f -', stdin_data: manifest)
      end

      def add_sample_policy(project, policy_name: 'sample-policy')
        namespace = "#{project.name}-#{project.id}-production"
        network_policy = <<~YAML
          apiVersion: "cilium.io/v2"
          kind: CiliumNetworkPolicy
          metadata:
            name: #{policy_name}
            namespace: #{namespace}
          spec:
            endpointSelector:
              matchLabels:
                role: backend
            ingress:
            - fromEndpoints:
              - matchLabels:
                  role: frontend
        YAML
        shell('kubectl apply -f -', stdin_data: network_policy)
      end

      def fetch_external_ip_for_ingress
        `kubectl get svc --all-namespaces --no-headers=true -l  app.kubernetes.io/name=ingress-nginx -o custom-columns=:'status.loadBalancer.ingress[0].ip' | grep -v 'none'`
      end

      private

      def fetch_api_url
        `kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'`
      end

      def fetch_credentials
        return global_credentials unless rbac

        @provider.set_credentials(admin_user)
        create_service_account(admin_user)
        account_credentials
      end

      def admin_user
        @admin_user ||= "#{@provider.cluster_name}-admin"
      end

      def create_service_account(user)
        service_account = <<~YAML
          ---
          apiVersion: v1
          kind: ServiceAccount
          metadata:
            name: gitlab-account
            namespace: default
          ---
          kind: ClusterRoleBinding
          apiVersion: rbac.authorization.k8s.io/v1
          metadata:
            name: gitlab-account-binding
          subjects:
          - kind: ServiceAccount
            name: gitlab-account
            namespace: default
          roleRef:
            kind: ClusterRole
            name: cluster-admin
            apiGroup: rbac.authorization.k8s.io
        YAML

        shell('kubectl apply -f -', stdin_data: service_account)
      end

      def account_credentials
        secrets = JSON.parse(`kubectl get secrets -o json`)

        secrets['items'].find do |item|
          item['metadata']['annotations']['kubernetes.io/service-account.name'] == 'gitlab-account'
        end
      end

      def global_credentials
        JSON.parse(`kubectl get secrets -o jsonpath='{.items[0]}'`)
      end

      def validate_dependencies
        find_executable('kubectl') || raise("You must first install `kubectl` executable to run these tests.")
      end
    end
  end
end
