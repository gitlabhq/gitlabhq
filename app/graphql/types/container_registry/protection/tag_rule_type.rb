# frozen_string_literal: true

module Types
  module ContainerRegistry
    module Protection
      class TagRuleType < ::Types::BaseObject
        graphql_name 'ContainerProtectionTagRule'
        description 'A container repository tag protection rule designed to prevent users with a certain ' \
          'access level or lower from altering the container registry.'

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

        # rubocop:disable GraphQL/ExtractType -- These are stored as separate fields
        field :minimum_access_level_for_delete,
          Types::ContainerRegistry::Protection::TagRuleAccessLevelEnum,
          null: false,
          experiment: { milestone: '17.8' },
          description:
            'Minimum GitLab access level required to delete container image tags from the container repository. ' \
            'Valid values include `MAINTAINER`, `OWNER`, or `ADMIN`. ' \
            'If the value is `nil`, the default minimum access level is `DEVELOPER`.'

        field :minimum_access_level_for_push,
          Types::ContainerRegistry::Protection::TagRuleAccessLevelEnum,
          null: false,
          experiment: { milestone: '17.8' },
          description:
            'Minimum GitLab access level required to push container image tags to the container repository. ' \
            'Valid values include `MAINTAINER`, `OWNER`, or `ADMIN`. ' \
            'If the value is `nil`, the default minimum access level is `DEVELOPER`.'
        # rubocop:enable GraphQL/ExtractType -- These are stored as user preferences
      end
    end
  end
end
