# frozen_string_literal: true

module Types
  module Ci
    module JobTokenScope
      class PolicyTypesEnum < BaseEnum
        graphql_name 'CiJobTokenScopePolicyTypes'
        description 'CI_JOB_TOKEN policy type'

        value 'READ', value: :read, description: 'Read-only access to the resource.'
        value 'ADMIN', value: :admin, description: 'Admin access to the resource.'
      end
    end
  end
end
