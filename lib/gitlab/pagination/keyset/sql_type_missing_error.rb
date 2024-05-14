# frozen_string_literal: true
module Gitlab
  module Pagination
    module Keyset
      class SqlTypeMissingError < StandardError
        def self.for_column(column)
          message = <<~TEXT
          The "sql_type" attribute is not set for the following column definition:
          #{column.attribute_name}

          See the ColumnOrderDefinition class for more context.
          TEXT

          new(message)
        end
      end
    end
  end
end
