# frozen_string_literal: true

module Gitlab
  module Kubernetes
    class RoleBinding
      def initialize(name:, role_name:, role_kind:, namespace:, service_account_name:)
        @name = name
        @role_name = role_name
        @role_kind = role_kind
        @namespace = namespace
        @service_account_name = service_account_name
      end

      def generate
        ::Kubeclient::Resource.new.tap do |resource|
          resource.metadata = metadata
          resource.roleRef  = role_ref
          resource.subjects = subjects
        end
      end

      private

      attr_reader :name, :role_name, :role_kind, :namespace, :service_account_name

      def metadata
        { name: name, namespace: namespace }
      end

      def role_ref
        {
          apiGroup: 'rbac.authorization.k8s.io',
          kind: role_kind,
          name: role_name
        }
      end

      def subjects
        [
          {
            kind: 'ServiceAccount',
            name: service_account_name,
            namespace: namespace
          }
        ]
      end
    end
  end
end
