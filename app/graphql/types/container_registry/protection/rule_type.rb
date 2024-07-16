# frozen_string_literal: true

module Types
  module ContainerRegistry
    module Protection
      class RuleType < ::Types::BaseObject
        graphql_name 'ContainerRegistryProtectionRule'
        description 'A container registry protection rule designed to prevent users with a certain ' \
                    'access level or lower from altering the container registry.'

        authorize :admin_container_image

        field :id,
          ::Types::GlobalIDType[::ContainerRegistry::Protection::Rule],
          null: false,
          alpha: { milestone: '16.6' },
          description: 'ID of the container registry protection rule.'

        field :repository_path_pattern,
          GraphQL::Types::String,
          null: false,
          alpha: { milestone: '16.6' },
          description:
            'Container repository path pattern protected by the protection rule. ' \
            'For example, `my-project/my-container-*`. Wildcard character `*` allowed.'

        field :minimum_access_level_for_delete,
          Types::ContainerRegistry::Protection::RuleAccessLevelEnum,
          null: true,
          alpha: { milestone: '16.6' },
          description:
            'Minimum GitLab access level to allow to delete container images from the container registry. ' \
            'For example, `MAINTAINER`, `OWNER`, or `ADMIN`. ' \
            'If the value is `nil`, the minimum access level for delete is ignored. ' \
            'Users with at least the Developer role are allowed to delete container images.'

        field :minimum_access_level_for_push,
          Types::ContainerRegistry::Protection::RuleAccessLevelEnum,
          null: true,
          alpha: { milestone: '16.6' },
          description:
            'Minimum GitLab access level to allow to push container images to the container registry. ' \
            'For example, `MAINTAINER`, `OWNER`, or `ADMIN`. ' \
            'If the value is `nil`, the minimum access level for push is ignored. ' \
            'Users with at least the Developer role are allowed to push container images.'
      end
    end
  end
end
