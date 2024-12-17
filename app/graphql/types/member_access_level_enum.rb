# frozen_string_literal: true

module Types
  class MemberAccessLevelEnum < BaseEnum
    graphql_name 'MemberAccessLevel'
    description 'Access level of a group or project member'

    def self.descriptions
      Gitlab::Access.option_descriptions
    end

    value 'GUEST', value: Gitlab::Access::GUEST, description: descriptions[Gitlab::Access::GUEST]
    value 'PLANNER', value: Gitlab::Access::PLANNER, description: descriptions[Gitlab::Access::PLANNER]
    value 'REPORTER', value: Gitlab::Access::REPORTER, description: descriptions[Gitlab::Access::REPORTER]
    value 'DEVELOPER', value: Gitlab::Access::DEVELOPER, description: descriptions[Gitlab::Access::DEVELOPER]
    value 'MAINTAINER', value: Gitlab::Access::MAINTAINER, description: descriptions[Gitlab::Access::MAINTAINER]
    value 'OWNER', value: Gitlab::Access::OWNER, description: descriptions[Gitlab::Access::OWNER]
  end
end

Types::MemberAccessLevelEnum.prepend_mod_with('Types::MemberAccessLevelEnum')
