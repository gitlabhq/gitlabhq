# frozen_string_literal: true

module Gitlab
  module Kubernetes
    class ServiceAccountToken
      attr_reader :name, :service_account_name, :namespace_name

      def initialize(name, service_account_name, namespace_name)
        @name = name
        @service_account_name = service_account_name
        @namespace_name = namespace_name
      end

      def generate
        ::Kubeclient::Resource.new(metadata: metadata, type: service_acount_token_type)
      end

      private

      # as per https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/#to-create-additional-api-tokens
      def service_acount_token_type
        'kubernetes.io/service-account-token'
      end

      def metadata
        {
          name: name,
          namespace: namespace_name,
          annotations: {
            "kubernetes.io/service-account.name": service_account_name
          }
        }
      end
    end
  end
end
