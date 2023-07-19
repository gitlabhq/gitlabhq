# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module SchemaObjects
        class Column
          def initialize(adapter)
            @adapter = adapter
          end

          attr_reader :adapter

          def name
            adapter.name
          end

          def table_name
            adapter.table_name
          end

          def partition_key?
            adapter.partition_key?
          end

          def statement
            [adapter.name, adapter.data_type, adapter.default, adapter.nullable].compact.join(' ')
          end
        end
      end
    end
  end
end
