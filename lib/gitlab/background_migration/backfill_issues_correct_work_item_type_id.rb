# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillIssuesCorrectWorkItemTypeId < BatchedMigrationJob
      operation_name :update_issues_correct_work_item_type_id
      feature_category :team_planning

      def perform
        each_sub_batch do |sub_batch|
          first, last = sub_batch.pick(Arel.sql('min(id), max(id)'))

          connection.execute(
            <<~SQL
              UPDATE
                "issues"
              SET
                "correct_work_item_type_id" = "work_item_types"."correct_id",
                "author_id_convert_to_bigint" = "issues"."author_id",
                "closed_by_id_convert_to_bigint" = "issues"."closed_by_id",
                "duplicated_to_id_convert_to_bigint" = "issues"."duplicated_to_id",
                "id_convert_to_bigint" = "issues"."id",
                "last_edited_by_id_convert_to_bigint" = "issues"."last_edited_by_id",
                "milestone_id_convert_to_bigint" = "issues"."milestone_id",
                "moved_to_id_convert_to_bigint" = "issues"."moved_to_id",
                "project_id_convert_to_bigint" = "issues"."project_id",
                "promoted_to_epic_id_convert_to_bigint" = "issues"."promoted_to_epic_id",
                "updated_by_id_convert_to_bigint" = "issues"."updated_by_id"
              FROM
                "work_item_types"
              WHERE
                "issues"."work_item_type_id" = "work_item_types"."id"
                AND "issues"."id" BETWEEN #{first}
                AND #{last}
            SQL
          )
        end
      end
    end
  end
end
