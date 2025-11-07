# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Migration/BatchedMigrationBaseClass -- This is indirectly deriving from the correct base class
    class BackfillMergeRequestFileDiffsPartitionedTable < BackfillPartitionedTable
      extend ::Gitlab::Utils::Override

      feature_category :source_code_management

      cursor :merge_request_diff_id, :relative_order

      override :perform
      def perform
        column_values = connection.columns(batch_table).map do |column|
          case column.name
          when 'new_path'
            'NULLIF("merge_request_diff_files"."new_path", "merge_request_diff_files"."old_path")'
          when 'project_id'
            'COALESCE("merge_request_diff_files"."project_id", "merge_request_diffs"."project_id")'
          else
            connection.quote_column_name(column.name)
          end
        end.join(', ')

        each_sub_batch do |relation|
          connection.execute(<<~SQL)
            INSERT INTO #{partitioned_table} (#{connection.columns(batch_table).map do |c|
              connection.quote_column_name(c.name)
            end.join(', ')})
            #{relation.joins('INNER JOIN "merge_request_diffs" ON "merge_request_diffs"."id" = "merge_request_diff_files"."merge_request_diff_id"').select(column_values).to_sql}
            ON CONFLICT (#{connection.primary_keys(partitioned_table).join(', ')}) DO NOTHING
          SQL
        end
      end
    end
    # rubocop: enable Migration/BatchedMigrationBaseClass
  end
end
