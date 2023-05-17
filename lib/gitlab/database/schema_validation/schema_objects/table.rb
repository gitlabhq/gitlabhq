# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      module SchemaObjects
        class Table
          def initialize(name, columns)
            @name = name
            @columns = columns
          end

          attr_reader :name, :columns

          def table_name
            name
          end

          def statement
            format('CREATE TABLE %s (%s)', name, columns_statement)
          end

          def fetch_column_by_name(column_name)
            columns.find { |column| column.name == column_name }
          end

          def column_exists?(column_name)
            fetch_column_by_name(column_name).present?
          end

          private

          def columns_statement
            columns.reject(&:partition_key?).map(&:statement).join(', ')
          end
        end
      end
    end
  end
end
