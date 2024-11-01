# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class CreateComplianceStandardsAdherence < BatchedMigrationJob
      feature_category :compliance_management

      def perform
        # no-op. The logic is defined in EE module.
      end
    end
  end
end

::Gitlab::BackgroundMigration::CreateComplianceStandardsAdherence.prepend_mod
