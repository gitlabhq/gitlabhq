# frozen_string_literal: true

module Gitlab
  module Database
    module PartitioningMigrationHelpers
      class PartitionedForeignKeyValidator < ActiveModel::Validator
        def validate(record)
          validate_key_part(record, :from_table, :from_column)
          validate_key_part(record, :to_table, :to_column)
        end

        private

        def validate_key_part(record, table_field, column_field)
          if !connection.table_exists?(record[table_field])
            record.errors.add(table_field, 'must be a valid table')
          elsif !connection.column_exists?(record[table_field], record[column_field])
            record.errors.add(column_field, 'must be a valid column')
          end
        end

        def connection
          ActiveRecord::Base.connection
        end
      end
    end
  end
end
