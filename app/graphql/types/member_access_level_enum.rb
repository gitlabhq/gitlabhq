# frozen_string_literal: true

module Types
  class MemberAccessLevelEnum < BaseEnum
    graphql_name 'MemberAccessLevel'
    description 'Access level of a group or project member'

    value 'GUEST', value: Gitlab::Access::GUEST, description: 'Guest access.'
    value 'REPORTER', value: Gitlab::Access::REPORTER, description: 'Reporter access.'
    value 'DEVELOPER', value: Gitlab::Access::DEVELOPER, description: 'Developer access.'
    value 'MAINTAINER', value: Gitlab::Access::MAINTAINER, description: 'Maintainer access.'
    value 'OWNER', value: Gitlab::Access::OWNER, description: 'Owner access.'
  end
end

Types::MemberAccessLevelEnum.prepend_mod_with('Types::MemberAccessLevelEnum')
