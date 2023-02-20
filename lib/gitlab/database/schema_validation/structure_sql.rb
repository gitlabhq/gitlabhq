# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      class StructureSql
        def initialize(structure_file_path)
          @structure_file_path = structure_file_path
        end

        def indexes
          @indexes ||= index_statements.map do |index_statement|
            index_statement.relation.schemaname = "public" if index_statement.relation.schemaname == ''

            Index.new(index_statement)
          end
        end

        private

        attr_reader :structure_file_path

        def index_statements
          parsed_structure_file.tree.stmts.filter_map { |s| s.stmt.index_stmt }
        end

        def parsed_structure_file
          PgQuery.parse(File.read(structure_file_path))
        end
      end
    end
  end
end
