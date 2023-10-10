# frozen_string_literal: true

module Types
  module Packages
    module Protection
      class RuleAccessLevelEnum < BaseEnum
        graphql_name 'PackagesProtectionRuleAccessLevel'
        description 'Access level of a package protection rule resource'

        value 'DEVELOPER', value: Gitlab::Access::DEVELOPER, description: 'Developer access.'
        value 'MAINTAINER', value: Gitlab::Access::MAINTAINER, description: 'Maintainer access.'
        value 'OWNER', value: Gitlab::Access::OWNER, description: 'Owner access.'
      end
    end
  end
end
