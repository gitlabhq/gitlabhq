# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDescriptionVersionsNamespace < BatchedMigrationJob
      operation_name :update_namespace_id
      feature_category :team_planning

      def perform
        each_sub_batch do |sub_batch|
          update_issue_records(sub_batch)
          update_merge_request_records(sub_batch)
          update_epic_records(sub_batch)
          delete_invalid_records(sub_batch)
        end
      end

      private

      def update_issue_records(sub_batch)
        connection.execute(
          <<~SQL
            UPDATE "description_versions"
            SET
              "namespace_id" = "issues"."namespace_id"
            FROM
              "issues"
            WHERE
              "description_versions"."issue_id" = "issues"."id"
              AND "description_versions"."id" IN (#{sub_batch.select(:id).to_sql})
          SQL
        )
      end

      def update_merge_request_records(sub_batch)
        connection.execute(
          <<~SQL
            UPDATE "description_versions"
            SET
              "namespace_id" = "projects"."project_namespace_id"
            FROM
              "merge_requests" INNER JOIN "projects" ON "merge_requests"."target_project_id" = "projects"."id"
            WHERE
              "description_versions"."merge_request_id" = "merge_requests"."id"
              AND "description_versions"."id" IN (#{sub_batch.select(:id).to_sql})
          SQL
        )
      end

      def update_epic_records(sub_batch)
        connection.execute(
          <<~SQL
            UPDATE "description_versions"
            SET
              "namespace_id" = "epics"."group_id"
            FROM
              "epics"
            WHERE
              "description_versions"."epic_id" = "epics"."id"
              AND "description_versions"."id" IN (#{sub_batch.select(:id).to_sql})
          SQL
        )
      end

      def delete_invalid_records(sub_batch)
        connection.execute(
          <<~SQL
            DELETE FROM
              description_versions
            WHERE
              "description_versions"."id" IN (#{sub_batch.select(:id).to_sql})
              AND (
                num_nonnulls(
                  issue_id, merge_request_id, epic_id
                ) > 1
                OR num_nonnulls(
                  issue_id, merge_request_id, epic_id
                ) < 1
              )
          SQL
        )
      end
    end
  end
end
