# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      class SwapColumns
        delegate :quote_table_name, :quote_column_name, :clear_cache!, to: :@migration_context

        def initialize(migration_context:, table:, column1:, column2:)
          @migration_context = migration_context
          @table = table
          @column_name1 = column1
          @column_name2 = column2
        end

        def execute
          rename_column(@table, @column_name1, :temp_name_for_renaming)
          rename_column(@table, @column_name2, @column_name1)
          rename_column(@table, :temp_name_for_renaming, @column_name2)
        end

        private

        # Rails' `rename_column` will rename related indexes
        # using a format e.g. `index_{TABLE_NAME}_on_{KEY1}_and_{KEY2}`
        # This will break the migration if the formated index name is longer than 63 chars, e.g.
        # `index_ci_pipeline_variables_on_pipeline_id_convert_to_bigint_and_key`
        # Therefore, we need to duplicate what Rails has done here without the part renaming related indexes
        def rename_column(table_name, column_name, column2_name)
          clear_cache!
          @migration_context.execute <<~SQL
            ALTER TABLE #{quote_table_name(table_name)}
              RENAME COLUMN #{quote_column_name(column_name)} TO #{quote_column_name(column2_name)}
          SQL
        end
      end
    end
  end
end
