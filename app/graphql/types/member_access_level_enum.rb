# frozen_string_literal: true

module Types
  class MemberAccessLevelEnum < BaseEnum
    graphql_name 'MemberAccessLevel'
    description 'Access level of a group or project member'

    def self.descriptions
      Gitlab::Access.option_descriptions
    end

    value 'GUEST', value: Gitlab::Access::GUEST, description: descriptions[:guest]
    value 'REPORTER', value: Gitlab::Access::REPORTER, description: descriptions[:reporter]
    value 'DEVELOPER', value: Gitlab::Access::DEVELOPER, description: descriptions[:developer]
    value 'MAINTAINER', value: Gitlab::Access::MAINTAINER, description: descriptions[:maintainer]
    value 'OWNER', value: Gitlab::Access::OWNER, description: descriptions[:owner]
  end
end

Types::MemberAccessLevelEnum.prepend_mod_with('Types::MemberAccessLevelEnum')
