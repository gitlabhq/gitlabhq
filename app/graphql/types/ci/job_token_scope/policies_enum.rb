# frozen_string_literal: true

module Types
  module Ci
    module JobTokenScope
      class PoliciesEnum < BaseEnum
        graphql_name 'CiJobTokenScopePolicies'
        description 'CI_JOB_TOKEN policy'

        ::Ci::JobToken::Policies.all_policies.each do |policy|
          value policy[:value].to_s.upcase, value: policy[:value], description: policy[:description]
        end
      end
    end
  end
end
