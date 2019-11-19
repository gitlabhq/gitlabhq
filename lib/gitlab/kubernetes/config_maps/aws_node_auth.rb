# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module ConfigMaps
      class AwsNodeAuth
        attr_reader :node_role

        def initialize(node_role)
          @node_role = node_role
        end

        def generate
          Kubeclient::Resource.new(
            metadata: metadata,
            data: data
          )
        end

        private

        def metadata
          {
            'name' => 'aws-auth',
            'namespace' => 'kube-system'
          }
        end

        def data
          { 'mapRoles' => instance_role_config(node_role) }
        end

        def instance_role_config(role)
          [{
            'rolearn' => role,
            'username' => 'system:node:{{EC2PrivateDNSName}}',
            'groups' => [
              'system:bootstrappers',
              'system:nodes'
            ]
          }].to_yaml
        end
      end
    end
  end
end
