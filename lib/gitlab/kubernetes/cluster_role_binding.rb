# frozen_string_literal: true

module Gitlab
  module Kubernetes
    class ClusterRoleBinding
      attr_reader :name, :cluster_role_name, :subjects

      def initialize(name, cluster_role_name, subjects)
        @name = name
        @cluster_role_name = cluster_role_name
        @subjects = subjects
      end

      def generate
        ::Kubeclient::Resource.new.tap do |resource|
          resource.metadata = metadata
          resource.roleRef = role_ref
          resource.subjects = subjects
        end
      end

      private

      def metadata
        { name: name }
      end

      def role_ref
        {
          apiGroup: 'rbac.authorization.k8s.io',
          kind: 'ClusterRole',
          name: cluster_role_name
        }
      end
    end
  end
end
