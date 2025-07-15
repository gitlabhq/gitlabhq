# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Adapters
        class SequenceStructureSqlAdapter
          attr_reader :sequence_name, :schema_name
          attr_accessor :owner_table, :owner_column, :owner_schema

          def initialize(
            sequence_name:, schema_name: nil, owner_table: nil,
            owner_column: nil, owner_schema: nil)
            @sequence_name = sequence_name
            @schema_name = schema_name
            @owner_table = owner_table
            @owner_column = owner_column
            @owner_schema = owner_schema
          end

          # Fully qualified sequence name (schema.sequence_name)
          def name
            "#{schema}.#{sequence_name}"
          end

          # Just the column name
          def column_name
            owner_column
          end

          def table_name
            owner_table
          end

          # Fully qualified column reference (schema.table.column)
          def column_owner
            return unless owner_table && owner_column

            "#{column_schema}.#{owner_table}.#{owner_column}"
          end

          # Get the schema this sequence belongs to
          def schema
            schema_name || owner_schema || 'public'
          end

          def column_schema
            owner_schema || schema_name || 'public'
          end

          def to_s
            "SequenceStructureSqlAdapter(#{name} -> #{column_owner})"
          end

          def inspect
            "#<SequenceStructureSqlAdapter:#{object_id} #{name} -> #{column_owner}>"
          end
        end
      end
    end
  end
end
