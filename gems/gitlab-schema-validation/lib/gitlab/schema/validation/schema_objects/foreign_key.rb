# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module SchemaObjects
        class ForeignKey
          def initialize(adapter)
            @adapter = adapter
          end

          # Foreign key name should include the schema, as the same name could be used across different schemas
          #
          # @example public.foreign_key_name
          def name
            @name ||= adapter.name
          end

          def table_name
            @table_name ||= adapter.table_name
          end

          def statement
            @statement ||= adapter.statement
          end

          private

          attr_reader :adapter
        end
      end
    end
  end
end
