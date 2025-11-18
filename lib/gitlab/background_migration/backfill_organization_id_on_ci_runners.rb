# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillOrganizationIdOnCiRunners < BatchedMigrationJob
      operation_name :backfill_organization_id_on_ci_runners
      feature_category :runner_core

      DEFAULT_ORG_ID = 1

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.where.not(sharding_key_id: nil).update_all(organization_id: DEFAULT_ORG_ID)
        end
      end
    end
  end
end
