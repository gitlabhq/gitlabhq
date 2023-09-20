# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Style/Documentation
    class CreateComplianceStandardsAdherence < BatchedMigrationJob
      feature_category :compliance_management

      def perform
        # no-op. The logic is defined in EE module.
      end
    end
    # rubocop: enable Style/Documentation
  end
end

::Gitlab::BackgroundMigration::CreateComplianceStandardsAdherence.prepend_mod
