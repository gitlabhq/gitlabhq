# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Sources
        module ConnectionAdapters
          class ActiveRecordAdapter < Base
            extend Forwardable

            def_delegators :@connection, :current_schema

            def exec_query(sql, schemas)
              connection.exec_query(sql, nil, schemas)
            end

            def select_rows(sql, schemas)
              connection.select_rows(sql, nil, schemas)
            end
          end
        end
      end
    end
  end
end
