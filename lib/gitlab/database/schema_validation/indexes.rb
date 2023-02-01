# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      class Indexes
        def initialize(structure_file_path, database_name)
          @parsed_structure_file = PgQuery.parse(File.read(structure_file_path))
          @database_name = database_name
        end

        def missing_indexes
          structure_file_indexes.keys - database_indexes.keys
        end

        def extra_indexes
          database_indexes.keys - structure_file_indexes.keys
        end

        def wrong_indexes
          structure_file_indexes.filter_map do |index_name, index_stmt|
            database_index = database_indexes[index_name]

            next if database_index.nil?

            begin
              database_index = PgQuery.deparse_stmt(PgQuery.parse(database_index).tree.stmts.first.stmt.index_stmt)

              index_stmt.relation.schemaname = "public" if index_stmt.relation.schemaname == ''

              structure_sql_index = PgQuery.deparse_stmt(index_stmt)

              index_name unless database_index == structure_sql_index
            rescue PgQuery::ParseError
              index_name
            end
          end
        end

        private

        attr_reader :parsed_structure_file, :database_name

        def structure_file_indexes
          @structure_file_indexes ||= index_parsed_structure_file.each_with_object({}) do |tree, dic|
            index_stmt = tree.stmt.index_stmt

            dic[index_stmt.idxname] = index_stmt
          end
        end

        def index_parsed_structure_file
          @index_parsed_structure_file ||= parsed_structure_file.tree.stmts.reject { |s| s.stmt.index_stmt.nil? }
        end

        def database_indexes
          sql = <<~SQL
            SELECT indexname, indexdef
            FROM pg_indexes
            WHERE indexname NOT LIKE '%_pkey' AND schemaname IN ('public', 'gitlab_partitions_static');
          SQL

          @database_indexes ||= connection.exec_query(sql).rows.to_h
        end

        def connection
          @connection ||= Gitlab::Database.database_base_models[database_name].connection
        end
      end
    end
  end
end
