# frozen_string_literal: true

module Types
  module Terraform
    class StateProtectionRuleType < ::Types::BaseObject
      graphql_name 'TerraformStateProtectionRule'
      description 'A protection rule for Terraform state backends, controlling ' \
        'who can write to a state based on project role and request source.'

      authorize :read_terraform_state

      field :id,
        ::Types::GlobalIDType[::Terraform::StateProtectionRule],
        null: false,
        experiment: { milestone: '18.11' },
        description: 'Global ID of the Terraform state protection rule.'

      field :state_name,
        GraphQL::Types::String,
        null: false,
        experiment: { milestone: '18.11' },
        description: 'Terraform state name protected by the rule.'

      field :minimum_access_level_for_write,
        Types::Terraform::StateProtectionRuleAccessLevelEnum,
        null: false,
        experiment: { milestone: '18.11' },
        description: 'Minimum GitLab access level required to perform write operations ' \
          'on the Terraform state. Valid values include `DEVELOPER`, `MAINTAINER`, `OWNER`, or `ADMIN`.'

      field :allowed_from,
        Types::Terraform::StateProtectionRuleAllowedFromEnum,
        null: false,
        experiment: { milestone: '18.11' },
        description: 'Restriction on the source of write requests. ' \
          '`ANYWHERE` allows all sources, `CI_ONLY` requires a CI job token, ' \
          '`CI_ON_PROTECTED_BRANCH_ONLY` requires a CI job on a protected branch.'
    end
  end
end
