# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      class Database
        def initialize(connection)
          @connection = connection
        end

        def fetch_index_by_name(index_name)
          index_map[index_name]
        end

        def indexes
          index_map.values
        end

        private

        def index_map
          @index_map ||=
            fetch_indexes.transform_values! do |index_stmt|
              Index.new(PgQuery.parse(index_stmt).tree.stmts.first.stmt.index_stmt)
            end
        end

        attr_reader :connection

        def fetch_indexes
          sql = <<~SQL
            SELECT indexname, indexdef
            FROM pg_indexes
            WHERE indexname NOT LIKE '%_pkey' AND schemaname IN ('public', 'gitlab_partitions_static');
          SQL

          @fetch_indexes ||= connection.exec_query(sql).rows.to_h
        end
      end
    end
  end
end
