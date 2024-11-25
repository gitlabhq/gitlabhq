# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSoftwareLicenseSpdxIdentifierForSoftwareLicensePolicies < BatchedMigrationJob
      feature_category :security_policy_management

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::BackfillSoftwareLicenseSpdxIdentifierForSoftwareLicensePolicies.prepend_mod_with('Gitlab::BackgroundMigration::BackfillSoftwareLicenseSpdxIdentifierForSoftwareLicensePolicies') # rubocop:disable Layout/LineLength -- ignore
