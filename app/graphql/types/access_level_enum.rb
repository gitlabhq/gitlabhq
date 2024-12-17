# frozen_string_literal: true

module Types
  class AccessLevelEnum < BaseEnum
    graphql_name 'AccessLevelEnum'
    description 'Access level to a resource'

    value 'NO_ACCESS', value: Gitlab::Access::NO_ACCESS, description: 'No access.'
    value 'MINIMAL_ACCESS', value: Gitlab::Access::MINIMAL_ACCESS, description: 'Minimal access.'
    value 'GUEST', value: Gitlab::Access::GUEST, description: 'Guest access.'
    value 'PLANNER', value: Gitlab::Access::PLANNER, description: 'Planner access.'
    value 'REPORTER', value: Gitlab::Access::REPORTER, description: 'Reporter access.'
    value 'DEVELOPER', value: Gitlab::Access::DEVELOPER, description: 'Developer access.'
    value 'MAINTAINER', value: Gitlab::Access::MAINTAINER, description: 'Maintainer access.'
    value 'OWNER', value: Gitlab::Access::OWNER, description: 'Owner access.'
  end
end

Types::AccessLevelEnum.prepend_mod_with('Types::AccessLevelEnum')
