# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      module SchemaObjects
        class Column
          def initialize(adapter)
            @adapter = adapter
          end

          attr_reader :adapter

          delegate :name, :table_name, :partition_key?, to: :adapter

          def statement
            [name, adapter.data_type, adapter.default, adapter.nullable].compact.join(' ')
          end
        end
      end
    end
  end
end
