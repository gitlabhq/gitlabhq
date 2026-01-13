# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillUserAgentDetailsOrganizationId < BatchedMigrationJob
      operation_name :backfill_user_agent_details_organization_id
      feature_category :instance_resiliency

      ORGANIZATION_ID = 1

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .where(organization_id: nil)
            .update_all(organization_id: ORGANIZATION_ID)
        end
      end
    end
  end
end
