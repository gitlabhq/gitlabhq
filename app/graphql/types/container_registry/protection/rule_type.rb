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
          description: 'ID of the container repository protection rule.'

        field :repository_path_pattern,
          GraphQL::Types::String,
          null: false,
          description:
            'Container repository path pattern protected by the protection rule. ' \
            'Must start with the project’s full path. For example: `my-project/*-prod-*`. ' \
            'Wildcard character `*` is allowed anywhere after the project’s full path.'

        field :minimum_access_level_for_delete,
          Types::ContainerRegistry::Protection::RuleAccessLevelEnum,
          null: true,
          description:
            'Minimum GitLab access level required to delete container images from the container repository. ' \
            'Valid values include `MAINTAINER`, `OWNER`, or `ADMIN`. ' \
            'If the value is `nil`, the default minimum access level is `DEVELOPER`.'

        field :minimum_access_level_for_push,
          Types::ContainerRegistry::Protection::RuleAccessLevelEnum,
          null: true,
          description:
            'Minimum GitLab access level required to push container images to the container repository. ' \
            'Valid values include `MAINTAINER`, `OWNER`, or `ADMIN`. ' \
            'If the value is `nil`, the default minimum access level is `DEVELOPER`.'
      end
    end
  end
end
