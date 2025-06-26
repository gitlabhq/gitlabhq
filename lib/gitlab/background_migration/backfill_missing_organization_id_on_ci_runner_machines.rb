# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillMissingOrganizationIdOnCiRunnerMachines < BatchedMigrationJob
      operation_name :backfill_missing_organization_id_on_ci_runner_machines
      feature_category :fleet_visibility

      DEFAULT_ORG_ID = 1

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .where(organization_id: nil)
            .where.not(runner_type: 1)
            .update_all(organization_id: DEFAULT_ORG_ID)
        end
      end
    end
  end
end
