# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillIssuesCorrectWorkItemTypeId < BatchedMigrationJob
      operation_name :update_issues_correct_work_item_type_id
      feature_category :team_planning

      COLUMNS_CONVERT_TO_BIGINT = %w[
        author_id_convert_to_bigint
        closed_by_id_convert_to_bigint
        duplicated_to_id_convert_to_bigint
        id_convert_to_bigint
        last_edited_by_id_convert_to_bigint
        milestone_id_convert_to_bigint
        moved_to_id_convert_to_bigint
        project_id_convert_to_bigint
        promoted_to_epic_id_convert_to_bigint
        updated_by_id_convert_to_bigint
      ].freeze

      delegate :quote_column_name, :quote_table_name, to: :connection

      def perform
        each_sub_batch do |sub_batch|
          first, last = sub_batch.pick(Arel.sql('min(id), max(id)'))

          connection.execute(
            <<~SQL
              UPDATE
                "issues"
              SET
                "correct_work_item_type_id" = "work_item_types"."correct_id"
                #{bigint_assignments}
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

      private

      def bigint_assignments
        @bigint_assignments ||=
          COLUMNS_CONVERT_TO_BIGINT.filter_map do |bigint_column|
            next unless all_column_names.include?(bigint_column)

            source_column = bigint_column.sub('_convert_to_bigint', '')

            ",\n#{quote_column_name(bigint_column)} = #{quote_table_name(:issues)}.#{quote_column_name(source_column)}"
          end.join('')
      end

      def all_column_names
        @all_column_names ||= connection.columns(:issues).map(&:name)
      end
    end
  end
end
