# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module SchemaObjects
        class Index < Base
          def initialize(parsed_stmt, parent: nil)
            super(parsed_stmt)
            @parent = parent
          end

          def name
            parsed_stmt.idxname
          end

          def attachment
            [parsed_stmt.relation.schemaname, parsed_stmt.relation.relname, *parent] if parent
          end

          def schema_name
            parsed_stmt.relation.schemaname
          end

          # Schema and name of the parent index, or nil.
          attr_reader :parent

          def definition
            @definition ||= begin
              stmt = parsed_stmt.dup
              stmt.idxname = ''
              PgQuery.deparse_stmt(stmt)
            end
          end
        end
      end
    end
  end
end
