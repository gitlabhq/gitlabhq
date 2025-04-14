# frozen_string_literal: true

module Types
  module ContainerRegistry
    module Protection
      module AccessLevelInterface
        include BaseInterface

        field :minimum_access_level_for_delete,
          Types::ContainerRegistry::Protection::TagRuleAccessLevelEnum,
          null: true,
          experiment: { milestone: '17.8' },
          description:
            'Minimum GitLab access level required to delete container image tags from the container repository. ' \
            'Valid values include `MAINTAINER`, `OWNER`, or `ADMIN`. ' \
            'If the value is `nil`, no access level can delete tags. '

        field :minimum_access_level_for_push,
          Types::ContainerRegistry::Protection::TagRuleAccessLevelEnum,
          null: true,
          experiment: { milestone: '17.8' },
          description:
            'Minimum GitLab access level required to push container image tags to the container repository. ' \
            'Valid values include `MAINTAINER`, `OWNER`, or `ADMIN`. ' \
            'If the value is `nil`, no access level can push tags. '

        field :immutable,
          GraphQL::Types::Boolean,
          null: false,
          method: :immutable?,
          experiment: { milestone: '17.11' },
          description: 'Returns true when tag rule is for tag immutability. Otherwise, false.'
      end
    end
  end
end
