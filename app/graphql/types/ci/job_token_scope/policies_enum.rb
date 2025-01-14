# frozen_string_literal: true

module Types
  module Ci
    module JobTokenScope
      class PoliciesEnum < BaseEnum
        graphql_name 'CiJobTokenScopePolicies'
        description 'CI_JOB_TOKEN policy'

        ::Ci::JobToken::Policies.all_values.each do |policy|
          value policy.upcase, value: policy, description: policy.titleize
        end
      end
    end
  end
end
