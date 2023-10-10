# frozen_string_literal: true

module Types
  module Packages
    module Protection
      class RulePackageTypeEnum < BaseEnum
        graphql_name 'PackagesProtectionRulePackageType'
        description 'Package type of a package protection rule resource'

        ::Packages::Protection::Rule.package_types.each_key do |package_type|
          value package_type.upcase, value: package_type,
            description: "Packages of the #{package_type} format"
        end
      end
    end
  end
end
