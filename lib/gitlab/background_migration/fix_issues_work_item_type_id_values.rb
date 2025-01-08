# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class FixIssuesWorkItemTypeIdValues < BatchedMigrationJob
      operation_name :update_issues_work_item_type_id
      feature_category :team_planning

      def perform
        each_sub_batch do |sub_batch|
          first, last = sub_batch.pick(Arel.sql('min(id), max(id)'))

          connection.execute(
            <<~SQL
              UPDATE
                "issues"
              SET
                "work_item_type_id" = "work_item_types"."id"
              FROM
                "work_item_types"
              WHERE
                "issues"."correct_work_item_type_id" = "work_item_types"."correct_id"
                AND "issues"."id" BETWEEN #{first}
                AND #{last}
            SQL
          )
        end
      end
    end
  end
end
