# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Sources
        module ConnectionAdapters
          class ActiveRecordAdapter < Base
            extend Forwardable

            def_delegators :@connection, :current_schema, :transaction

            def exec_query(sql, schemas)
              connection.exec_query(sql, nil, schemas)
            end

            # Routed like transaction, so SET LOCAL and the read share one connection.
            def select_rows(sql, schemas)
              connection.exec_query(sql, nil, schemas).rows
            end
          end
        end
      end
    end
  end
end
