# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Adapters
        class ForeignKeyDatabaseAdapter
          def initialize(query_result)
            @query_result = query_result
          end

          def name
            "#{query_result['schema']}.#{query_result['foreign_key_name']}"
          end

          def table_name
            query_result['table_name']
          end

          def statement
            query_result['foreign_key_definition']
          end

          private

          attr_reader :query_result
        end
      end
    end
  end
end
