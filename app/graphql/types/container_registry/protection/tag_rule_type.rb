# frozen_string_literal: true

module Types
  module ContainerRegistry
    module Protection
      class TagRuleType < ::Types::BaseObject
        graphql_name 'ContainerProtectionTagRule'
        description 'A container repository tag protection rule designed to prevent users with a certain ' \
          'access level or lower from altering the container registry.'

        implements Types::ContainerRegistry::Protection::AccessLevelInterface

        authorize :admin_container_image

        field :id,
          ::Types::GlobalIDType[::ContainerRegistry::Protection::TagRule],
          null: false,
          experiment: { milestone: '17.8' },
          description: 'ID of the container repository tag protection rule.'

        field :tag_name_pattern,
          GraphQL::Types::String,
          null: false,
          experiment: { milestone: '17.8' },
          description:
            'The pattern that matches container image tags to protect. ' \
            'For example, `v1.*`. Wildcard character `*` allowed.'
      end
    end
  end
end
