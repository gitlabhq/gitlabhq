# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      class SwapColumnsDefault
        delegate(
          :change_column_default, :quote_table_name, :quote_column_name, :column_for,
          to: :@migration_context
        )

        def initialize(migration_context:, table:, column1:, column2:)
          @migration_context = migration_context
          @table = table
          @column_name1 = column1
          @column_name2 = column2
        end

        def execute
          default1 = find_default_by(@column_name1)
          default2 = find_default_by(@column_name2)
          return if default1 == default2

          change_sequence_owner_if(default1[:sequence_name], @column_name2)
          change_sequence_owner_if(default2[:sequence_name], @column_name1)

          change_column_default(@table, @column_name1, default2[:default])
          change_column_default(@table, @column_name2, default1[:default])
        end

        private

        def change_sequence_owner_if(sequence_name, column_name)
          return if sequence_name.blank?

          @migration_context.execute(<<~SQL.squish)
            ALTER SEQUENCE #{quote_table_name(sequence_name)}
            OWNED BY #{quote_table_name(@table)}.#{quote_column_name(column_name)}
          SQL
        end

        def find_default_by(name)
          column = column_for(@table, name)
          if column.default_function.present?
            {
              default: -> { column.default_function },
              sequence_name: extract_sequence_name_from(column.default_function)
            }
          else
            {
              default: column.default
            }
          end
        end

        def extract_sequence_name_from(expression)
          expression[/nextval\('([^']+)'/, 1]
        end
      end
    end
  end
end
