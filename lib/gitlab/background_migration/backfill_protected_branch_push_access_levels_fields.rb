# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillProtectedBranchPushAccessLevelsFields < BatchedMigrationJob
      operation_name :backfill_protected_branch_push_access_levels_fields
      feature_category :source_code_management

      COLUMNS_CONVERT_TO_BIGINT = %w[
        id_convert_to_bigint
        protected_branch_id_convert_to_bigint
        user_id_convert_to_bigint
        group_id_convert_to_bigint
        deploy_key_id_convert_to_bigint
      ].freeze

      delegate :quote_column_name, :quote_table_name, to: :connection

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(
            <<~SQL
              WITH filtered_relation AS MATERIALIZED (#{sub_batch.limit(100).to_sql})
              UPDATE protected_branch_push_access_levels
              SET protected_branch_namespace_id = protected_branches.namespace_id,
                protected_branch_project_id = protected_branches.project_id
                #{bigint_column_assignments}
              FROM filtered_relation INNER JOIN protected_branches
              ON protected_branches.id = filtered_relation.protected_branch_id
              WHERE protected_branch_push_access_levels.id = filtered_relation.id
            SQL
          )
        end
      end

      private

      def bigint_column_assignments
        @bigint_assignments ||=
          COLUMNS_CONVERT_TO_BIGINT.filter_map do |bigint_column|
            next unless all_column_names.include?(bigint_column)

            source_column = bigint_column.sub('_convert_to_bigint', '')

            ",\n#{quote_column_name(bigint_column)} = filtered_relation.#{quote_column_name(source_column)}"
          end.join('')
      end

      def all_column_names
        @all_column_names ||= connection.columns(:protected_branch_push_access_levels).map(&:name)
      end
    end
  end
end
