# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillResourceIterationEventsNamespaceId < BatchedMigrationJob
      operation_name :update_namespace_id
      feature_category :team_planning

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(
            <<~SQL
              WITH sub_batch AS MATERIALIZED (#{sub_batch.select(:id, :iteration_id).limit(sub_batch_size).to_sql})
              UPDATE
                "resource_iteration_events"
              SET
                "namespace_id" = "sprints"."group_id"
              FROM
                "sub_batch"
                INNER JOIN "sprints" ON "sprints"."id" = "sub_batch"."iteration_id"
              WHERE
                "resource_iteration_events"."id" = "sub_batch"."id"
            SQL
          )
        end
      end
    end
  end
end
