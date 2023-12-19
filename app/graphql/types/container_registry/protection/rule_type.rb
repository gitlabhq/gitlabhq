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
          description: 'ID of the container registry protection rule.'

        field :repository_path_pattern,
          GraphQL::Types::String,
          null: false,
          description:
            'Container repository path pattern protected by the protection rule. ' \
            'For example `my-project/my-container-*`. Wildcard character `*` allowed.'

        field :push_protected_up_to_access_level,
          Types::ContainerRegistry::Protection::RuleAccessLevelEnum,
          null: false,
          description:
            'Max GitLab access level to prevent from pushing container images to the container registry. ' \
            'For example `DEVELOPER`, `MAINTAINER`, `OWNER`.'

        field :delete_protected_up_to_access_level,
          Types::ContainerRegistry::Protection::RuleAccessLevelEnum,
          null: false,
          description:
            'Max GitLab access level to prevent from pushing container images to the container registry. ' \
            'For example `DEVELOPER`, `MAINTAINER`, `OWNER`.'
      end
    end
  end
end
