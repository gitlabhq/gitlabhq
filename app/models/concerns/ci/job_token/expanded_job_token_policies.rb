# frozen_string_literal: true

module Ci
  module JobToken
    module ExpandedJobTokenPolicies
      extend ActiveSupport::Concern

      ADMIN_POLICY_PREFIX = 'admin'
      READ_POLICY_PREFIX = 'read'

      def expanded_job_token_policies
        job_token_policies.flat_map do |policy|
          if policy.starts_with?(ADMIN_POLICY_PREFIX)
            admin_read_policy = policy.sub(ADMIN_POLICY_PREFIX, READ_POLICY_PREFIX)
            [policy.to_sym, admin_read_policy.to_sym]
          else
            policy.to_sym
          end
        end
      end
    end
  end
end
