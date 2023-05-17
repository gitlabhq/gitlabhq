# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Style/Documentation
    class BackfillComplianceViolations < Gitlab::BackgroundMigration::BatchedMigrationJob
      feature_category :compliance_management

      def perform
        # no-op. The logic is defined in EE module.
      end
    end
    # rubocop: enable Style/Documentation
  end
end

::Gitlab::BackgroundMigration::BackfillComplianceViolations.prepend_mod
