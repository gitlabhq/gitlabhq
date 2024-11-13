# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSecurityPolicies < BatchedMigrationJob
      feature_category :security_policy_management

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::BackfillSecurityPolicies.prepend_mod_with('Gitlab::BackgroundMigration::BackfillSecurityPolicies') # rubocop:disable Layout/LineLength -- ignore
