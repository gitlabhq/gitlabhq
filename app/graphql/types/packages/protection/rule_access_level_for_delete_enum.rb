# frozen_string_literal: true

module Types
  module Packages
    module Protection
      class RuleAccessLevelForDeleteEnum < BaseEnum
        graphql_name 'PackagesProtectionRuleAccessLevelForDelete'
        description 'Access level for the deletion of a package protection rule resource.'

        ::Packages::Protection::Rule.minimum_access_level_for_deletes.each_key do |access_level_key|
          value access_level_key.upcase,
            value: access_level_key.to_s,
            description: "#{access_level_key.capitalize} access. " \
              'Available only when feature flag `packages_protected_packages_delete` is enabled.'
        end
      end
    end
  end
end
