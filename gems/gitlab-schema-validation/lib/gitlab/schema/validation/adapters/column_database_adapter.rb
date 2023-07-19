# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Adapters
        class ColumnDatabaseAdapter
          def initialize(query_result)
            @query_result = query_result
          end

          def name
            @name ||= query_result['column_name']
          end

          def table_name
            query_result['table_name']
          end

          def data_type
            query_result['data_type']
          end

          def default
            return unless query_result['column_default']

            return if name == 'id' || query_result['column_default'].include?('nextval')

            "DEFAULT #{query_result['column_default']}"
          end

          def nullable
            'NOT NULL' if query_result['not_null']
          end

          def partition_key?
            query_result['partition_key']
          end

          private

          attr_reader :query_result
        end
      end
    end
  end
end
