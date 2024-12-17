# frozen_string_literal: true

module Types
  module ContainerRegistry
    module Protection
      class RuleType < ::Types::BaseObject
        graphql_name 'ContainerProtectionRepositoryRule'
        description 'A container repository protection rule designed to prevent users with a certain ' \
          'access level or lower from altering the container registry.'

        authorize :admin_container_image

        field :id,
          ::Types::GlobalIDType[::ContainerRegistry::Protection::Rule],
          null: false,
          experiment: { milestone: '16.6' },
          description: 'ID of the container repository protection rule.'

        field :repository_path_pattern,
          GraphQL::Types::String,
          null: false,
          experiment: { milestone: '16.6' },
          description:
            'Container repository path pattern protected by the protection rule. ' \
            'For example, `my-project/my-container-*`. Wildcard character `*` allowed.'

        field :minimum_access_level_for_delete,
          Types::ContainerRegistry::Protection::RuleAccessLevelEnum,
          null: true,
          experiment: { milestone: '16.6' },
          description:
            'Minimum GitLab access level required to delete container images from the container repository. ' \
            'For example, `MAINTAINER`, `OWNER`, or `ADMIN`. ' \
            'If the value is `nil`, the minimum access level is ignored. ' \
            'Users with at least the Developer role can delete container images.'

        field :minimum_access_level_for_push,
          Types::ContainerRegistry::Protection::RuleAccessLevelEnum,
          null: true,
          experiment: { milestone: '16.6' },
          description:
            'Minimum GitLab access level required to push container images to the container repository. ' \
            'For example, `MAINTAINER`, `OWNER`, or `ADMIN`. ' \
            'If the value is `nil`, the minimum access level is ignored. ' \
            'Users with at least the Developer role can push container images.'
      end
    end
  end
end
