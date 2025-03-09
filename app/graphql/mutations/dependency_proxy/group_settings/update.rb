# frozen_string_literal: true

module Mutations
  module DependencyProxy
    module GroupSettings
      class Update < Mutations::BaseMutation
        graphql_name 'UpdateDependencyProxySettings'

        include Mutations::ResolvesGroup

        description 'These settings can be adjusted only by the group Owner.'

        authorize :admin_dependency_proxy

        argument :group_path,
          GraphQL::Types::ID,
          required: true,
          description: 'Group path for the group dependency proxy.'

        argument :enabled,
          GraphQL::Types::Boolean,
          required: false,
          description: copy_field_description(Types::DependencyProxy::ImageTtlGroupPolicyType, :enabled)

        argument :identity, GraphQL::Types::String, required: false,
          experiment: { milestone: '17.10' },
          description: 'Identity credential used to authenticate with Docker Hub when pulling images. ' \
            'Can be a username (for password or PAT) or organization name (for OAT). ' \
            'Ignored if `dependency_proxy_containers_docker_hub_credentials` is disabled.'

        argument :secret, GraphQL::Types::String, required: false,
          experiment: { milestone: '17.10' },
          description: 'Secret credential used to authenticate with Docker Hub when pulling images. ' \
            'Can be a password, Personal Access Token (PAT), or Organization Access Token (OAT). ' \
            'Ignored if `dependency_proxy_containers_docker_hub_credentials` is disabled.'

        field :dependency_proxy_setting,
          Types::DependencyProxy::GroupSettingType,
          null: true,
          description: 'Group dependency proxy settings after mutation.'

        def resolve(group_path:, **args)
          group = authorized_find!(group_path: group_path)

          unless Feature.enabled?(:dependency_proxy_containers_docker_hub_credentials, group)
            args.delete(:identity)
            args.delete(:secret)
          end

          result = ::DependencyProxy::GroupSettings::UpdateService
            .new(container: group, current_user: current_user, params: args)
            .execute

          {
            dependency_proxy_setting: result.payload[:dependency_proxy_setting],
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
