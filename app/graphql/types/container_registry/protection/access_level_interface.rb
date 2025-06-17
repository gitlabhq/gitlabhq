# frozen_string_literal: true

module Types
  module ContainerRegistry
    module Protection
      module AccessLevelInterface
        include BaseInterface

        field :minimum_access_level_for_delete,
          Types::ContainerRegistry::Protection::TagRuleAccessLevelEnum,
          null: false,
          experiment: { milestone: '17.8' },
          description:
            'Minimum GitLab access level required to delete container image tags from the container repository. ' \
            'Valid values include `MAINTAINER`, `OWNER`, or `ADMIN`. '

        field :minimum_access_level_for_push,
          Types::ContainerRegistry::Protection::TagRuleAccessLevelEnum,
          null: false,
          experiment: { milestone: '17.8' },
          description:
            'Minimum GitLab access level required to push container image tags to the container repository. ' \
            'Valid values include `MAINTAINER`, `OWNER`, or `ADMIN`. '
      end
    end
  end
end

Types::ContainerRegistry::Protection::AccessLevelInterface.prepend_mod
