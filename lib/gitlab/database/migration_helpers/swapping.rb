# frozen_string_literal: true

module Gitlab
  module Database
    module MigrationHelpers
      module Swapping
        include ::Gitlab::Database::SchemaHelpers
        include ::Gitlab::Database::MigrationHelpers::V2

        def swap_columns(table, column1, column2)
          ::Gitlab::Database::Migrations::SwapColumns.new(
            migration_context: self,
            table: table,
            column1: column1,
            column2: column2
          ).execute
        end

        def swap_columns_default(table, column1, column2)
          ::Gitlab::Database::Migrations::SwapColumnsDefault.new(
            migration_context: self,
            table: table,
            column1: column1,
            column2: column2
          ).execute
        end

        def swap_foreign_keys(table, foreign_key1, foreign_key2)
          rename_constraint(table, foreign_key1, :temp_name_for_renaming)
          rename_constraint(table, foreign_key2, foreign_key1)
          rename_constraint(table, :temp_name_for_renaming, foreign_key2)
        end

        def swap_indexes(table, index1, index2, schema: nil)
          identifier = "index_#{index1}_on_#{table}"
          # Check Gitlab::Database::MigrationHelpers#concurrent_foreign_key_name()
          # for info on why we use a hash
          hashed_identifier = Digest::SHA256.hexdigest(identifier).first(10)

          temp_index = "temp_#{hashed_identifier}"

          rename_index_with_schema(table, index1, temp_index, schema: schema)
          rename_index_with_schema(table, index2, index1, schema: schema)
          rename_index_with_schema(table, temp_index, index2, schema: schema)
        end
      end
    end
  end
end
