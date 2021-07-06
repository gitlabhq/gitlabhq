# frozen_string_literal: true

module Types
  class DeploymentTierEnum < BaseEnum
    graphql_name 'DeploymentTier'
    description 'All environment deployment tiers.'

    value 'PRODUCTION', description: 'Production.', value: :production
    value 'STAGING', description: 'Staging.', value: :staging
    value 'TESTING', description: 'Testing.', value: :testing
    value 'DEVELOPMENT', description: 'Development.', value: :development
    value 'OTHER', description: 'Other.', value: :other
  end
end
