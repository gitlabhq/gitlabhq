# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillResourceLabelEventsNamespaceIdAndCleanInvalid < BatchedMigrationJob
      operation_name :set_namespace_id
      feature_category :team_planning

      def perform
        each_sub_batch do |sub_batch|
          clean_epic_records(sub_batch)
          update_issue_records(sub_batch)
          update_merge_request_records(sub_batch)
          update_epic_records(sub_batch)
        end
      end

      private

      def query_prefix(sub_batch, where_clause)
        <<~SQL
          WITH relation AS (
            #{sub_batch.limit(sub_batch_size).to_sql}
          ),
          filtered_relation AS (
            SELECT * FROM relation WHERE #{where_clause} LIMIT #{sub_batch_size}
          )
        SQL
      end

      def clean_epic_records(sub_batch)
        connection.execute(
          <<~SQL
            #{query_prefix(sub_batch, '(num_nonnulls(epic_id, issue_id) = 2)')}
            UPDATE "resource_label_events"
            SET
              "issue_id" = NULL
            FROM
              "filtered_relation"
            WHERE
              "resource_label_events"."id" = "filtered_relation"."id"
          SQL
        )
      end

      def update_issue_records(sub_batch)
        connection.execute(
          <<~SQL
            #{query_prefix(sub_batch, 'issue_id IS NOT NULL')}
            UPDATE "resource_label_events"
            SET
              "namespace_id" = "issues"."namespace_id"
            FROM
              "filtered_relation"
              INNER JOIN "issues" ON "filtered_relation"."issue_id" = "issues"."id"
            WHERE
              "resource_label_events"."id" = "filtered_relation"."id"
          SQL
        )
      end

      def update_merge_request_records(sub_batch)
        connection.execute(
          <<~SQL
            #{query_prefix(sub_batch, 'merge_request_id IS NOT NULL')}
            UPDATE "resource_label_events"
            SET
              "namespace_id" = "projects"."project_namespace_id"
            FROM
              filtered_relation
              INNER JOIN merge_requests ON filtered_relation.merge_request_id = merge_requests.id
              INNER JOIN projects ON projects.id = merge_requests.target_project_id
            WHERE
              "resource_label_events"."id" = "filtered_relation"."id"
          SQL
        )
      end

      def update_epic_records(sub_batch)
        connection.execute(
          <<~SQL
            #{query_prefix(sub_batch, 'epic_id IS NOT NULL')}
            UPDATE "resource_label_events"
            SET
              "namespace_id" = "epics"."group_id"
            FROM
              filtered_relation
              INNER JOIN epics ON filtered_relation.epic_id = epics.id
            WHERE
              "resource_label_events"."id" = "filtered_relation"."id"
          SQL
        )
      end
    end
  end
end
