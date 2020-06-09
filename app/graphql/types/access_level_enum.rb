# frozen_string_literal: true

module Types
  class AccessLevelEnum < BaseEnum
    graphql_name 'AccessLevelEnum'
    description 'Access level to a resource'

    value 'NO_ACCESS', value: Gitlab::Access::NO_ACCESS
    value 'GUEST', value: Gitlab::Access::GUEST
    value 'REPORTER', value: Gitlab::Access::REPORTER
    value 'DEVELOPER', value: Gitlab::Access::DEVELOPER
    value 'MAINTAINER', value: Gitlab::Access::MAINTAINER
    value 'OWNER', value: Gitlab::Access::OWNER
  end
end
