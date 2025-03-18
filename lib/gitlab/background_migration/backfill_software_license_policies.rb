# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSoftwareLicensePolicies < BatchedMigrationJob
      feature_category :security_policy_management

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::BackfillSoftwareLicensePolicies.prepend_mod
