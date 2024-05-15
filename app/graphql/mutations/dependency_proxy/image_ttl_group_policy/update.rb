# frozen_string_literal: true

module Mutations
  module DependencyProxy
    module ImageTtlGroupPolicy
      class Update < Mutations::BaseMutation
        graphql_name 'UpdateDependencyProxyImageTtlGroupPolicy'

        include Mutations::ResolvesGroup

        description 'These settings can be adjusted only by the group Owner.'

        authorize :admin_dependency_proxy

        argument :group_path,
          GraphQL::Types::ID,
          required: true,
          description: 'Group path for the group dependency proxy image TTL policy.'

        argument :enabled,
          GraphQL::Types::Boolean,
          required: false,
          description: copy_field_description(Types::DependencyProxy::ImageTtlGroupPolicyType, :enabled)

        argument :ttl,
          GraphQL::Types::Int,
          required: false,
          description: copy_field_description(Types::DependencyProxy::ImageTtlGroupPolicyType, :ttl)

        field :dependency_proxy_image_ttl_policy,
          Types::DependencyProxy::ImageTtlGroupPolicyType,
          null: true,
          description: 'Group image TTL policy after mutation.'

        def resolve(group_path:, **args)
          group = authorized_find!(group_path: group_path)

          result = ::DependencyProxy::ImageTtlGroupPolicies::UpdateService
            .new(container: group, current_user: current_user, params: args)
            .execute

          {
            dependency_proxy_image_ttl_policy: result.payload[:dependency_proxy_image_ttl_policy],
            errors: result.errors
          }
        end

        private

        def find_object(group_path:)
          resolve_group(full_path: group_path)
        end
      end
    end
  end
end
