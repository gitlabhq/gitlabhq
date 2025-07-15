# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module SchemaObjects
        class Sequence < Base
          def initialize(adapter)
            @adapter = adapter
          end

          # Sequence should include the schema, as the same name could be used across different schemas
          #
          # @example public.sequence_name
          def name
            @name ||= adapter.name
          end

          # Fully qualified column reference (schema.table.column)
          def owner
            @owner ||= adapter.column_owner
          end

          def table_name
            @table_name ||= adapter.table_name
          end

          def statement
            statements = "CREATE SEQUENCE #{name};"
            statements += "\nALTER SEQUENCE #{name} OWNED BY #{owner}" if owner
            statements
          end

          private

          attr_reader :adapter
        end
      end
    end
  end
end
