# frozen_string_literal: true

module Gitlab
  module Kubernetes
    class RoleBinding
      attr_reader :role_name, :namespace, :service_account_name

      def initialize(role_name:, namespace:, service_account_name:)
        @role_name = role_name
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

      def metadata
        { name: "gitlab-#{namespace}", namespace: namespace }
      end

      def role_ref
        {
          apiGroup: 'rbac.authorization.k8s.io',
          kind: 'Role',
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
