# frozen_string_literal: true

module Types
  module Security
    class PreferredLicenseSourceConfigurationEnum < BaseEnum
      graphql_name 'SecurityPreferredLicenseSourceConfiguration'

      value 'SBOM',
        value: 'sbom',
        description: 'Use the SBOM as a source of license information for dependencies.'

      value 'PMDB',
        value: 'pmdb',
        description: 'Use internal instance license database as a source of license information for dependencies.'
    end
  end
end
