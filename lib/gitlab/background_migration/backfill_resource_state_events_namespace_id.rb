# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillResourceStateEventsNamespaceId < BatchedMigrationJob
      operation_name :update_namespace_id
      feature_category :team_planning

      def perform
        each_sub_batch do |sub_batch|
          update_issue_records(sub_batch)
          update_merge_request_records(sub_batch)
          update_epic_records(sub_batch)
        end
      end

      private

      def update_issue_records(sub_batch)
        connection.execute(
          <<~SQL
            UPDATE "resource_state_events"
            SET
              "namespace_id" = "issues"."namespace_id"
            FROM
              "issues"
            WHERE
              "resource_state_events"."issue_id" = "issues"."id"
              AND "resource_state_events"."id" IN (#{sub_batch.select(:id).to_sql})
          SQL
        )
      end

      def update_merge_request_records(sub_batch)
        connection.execute(
          <<~SQL
            UPDATE "resource_state_events"
            SET
              "namespace_id" = "projects"."project_namespace_id"
            FROM
              "merge_requests" INNER JOIN "projects" ON "merge_requests"."target_project_id" = "projects"."id"
            WHERE
              "resource_state_events"."merge_request_id" = "merge_requests"."id"
              AND "resource_state_events"."id" IN (#{sub_batch.select(:id).to_sql})
          SQL
        )
      end

      def update_epic_records(sub_batch)
        connection.execute(
          <<~SQL
            UPDATE "resource_state_events"
            SET
              "namespace_id" = "epics"."group_id"
            FROM
              "epics"
            WHERE
              "resource_state_events"."epic_id" = "epics"."id"
              AND "resource_state_events"."id" IN (#{sub_batch.select(:id).to_sql})
          SQL
        )
      end
    end
  end
end
