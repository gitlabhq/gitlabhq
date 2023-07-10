# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Adapters
        class ForeignKeyStructureSqlAdapter
          STATEMENT_REGEX = /\bREFERENCES\s\K\S+\K\s\(/
          EXTRACT_REGEX = /\bFOREIGN KEY.*/

          def initialize(parsed_stmt)
            @parsed_stmt = parsed_stmt
          end

          def name
            "#{schema_name}.#{foreign_key_name}"
          end

          def table_name
            parsed_stmt.relation.relname
          end

          # PgQuery parses FK statements with an extra space in the referenced table column.
          # This extra space needs to be removed.
          #
          # @example REFERENCES ci_pipelines (id) => REFERENCES ci_pipelines(id)
          def statement
            deparse_stmt[EXTRACT_REGEX].gsub(STATEMENT_REGEX, '(')
          end

          private

          attr_reader :parsed_stmt

          def schema_name
            parsed_stmt.relation.schemaname
          end

          def foreign_key_name
            parsed_stmt.cmds.first.alter_table_cmd.def.constraint.conname
          end

          def deparse_stmt
            PgQuery.deparse_stmt(parsed_stmt)
          end
        end
      end
    end
  end
end
