# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillComplianceViolationNullTargetProjectIds < BatchedMigrationJob
      # This batched background migration is EE-only,
      # see ee/lib/ee/gitlab/background_migration/backfill_compliance_violation_null_target_project_ids.rb for
      # the actual migration code.

      feature_category :compliance_management

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::BackfillComplianceViolationNullTargetProjectIds.prepend_mod
