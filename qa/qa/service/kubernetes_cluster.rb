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
