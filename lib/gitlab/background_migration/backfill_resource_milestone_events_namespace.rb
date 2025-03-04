# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillResourceMilestoneEventsNamespace < BatchedMigrationJob
      operation_name :update_namespace_id # This is used as the key on collecting metrics
      feature_category :team_planning

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(
            <<~SQL
              UPDATE "resource_milestone_events"
              SET
                "namespace_id" = "issues"."namespace_id"
              FROM
                "issues"
              WHERE
                "resource_milestone_events"."issue_id" = "issues"."id"
                AND "resource_milestone_events"."id" IN (#{sub_batch.select(:id).to_sql})
            SQL
          )
          connection.execute(
            <<~SQL
              UPDATE "resource_milestone_events"
              SET
                "namespace_id" = "projects"."project_namespace_id"
              FROM
                "merge_requests" INNER JOIN "projects" ON "merge_requests"."target_project_id" = "projects"."id"
              WHERE
                "resource_milestone_events"."merge_request_id" = "merge_requests"."id"
                AND "resource_milestone_events"."id" IN (#{sub_batch.select(:id).to_sql})
            SQL
          )
        end
      end
    end
  end
end
