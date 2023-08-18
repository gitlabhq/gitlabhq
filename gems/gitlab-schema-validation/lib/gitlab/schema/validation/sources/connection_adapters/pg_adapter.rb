# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Sources
        module ConnectionAdapters
          class PgAdapter < Base
            def initialize(connection)
              @connection = connection
              @connection.type_map_for_results = PG::BasicTypeMapForResults.new(connection)
            end

            def current_schema
              connection.exec('SELECT current_schema').first['current_schema']
            end

            def exec_query(sql, schemas)
              connection.exec(sql, schemas)
            end

            def select_rows(sql, schemas)
              exec_query(sql, schemas).values
            end
          end
        end
      end
    end
  end
end
