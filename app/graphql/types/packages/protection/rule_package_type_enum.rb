# frozen_string_literal: true

module Types
  module Packages
    module Protection
      class RulePackageTypeEnum < BaseEnum
        graphql_name 'PackagesProtectionRulePackageType'
        description 'Package type of a package protection rule resource'

        value 'CONAN',
          value: 'conan',
          description: 'Packages of the Conan format.'

        value 'HELM',
          value: 'helm',
          experiment: { milestone: '18.1' },
          description: 'Packages of the Helm format.' \
            'Available only when feature flag `packages_protected_packages_helm` is enabled.'

        value 'GENERIC',
          value: 'generic',
          description: 'Packages of the Generic format.'

        value 'MAVEN',
          value: 'maven',
          description: 'Packages of the Maven format.'

        value 'NPM',
          value: 'npm',
          description: 'Packages of the npm format.'

        value 'NUGET',
          value: 'nuget',
          experiment: { milestone: '18.0' },
          description: 'Packages of the NuGet format. ' \
            'Available only when feature flag `packages_protected_packages_nuget` is enabled.'

        value 'PYPI',
          value: 'pypi',
          description: 'Packages of the PyPI format.'
      end
    end
  end
end
