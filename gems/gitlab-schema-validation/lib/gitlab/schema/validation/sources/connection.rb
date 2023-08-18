# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Sources
        class AdapterNotSupportedError < StandardError
          def initialize(adapter)
            @adapter = adapter
          end

          def message
            "#{adapter} is not supported"
          end

          private

          attr_reader :adapter
        end

        class Connection
          CONNECTION_ADAPTERS = {
            'Gitlab::Database::LoadBalancing::ConnectionProxy' => ConnectionAdapters::ActiveRecordAdapter,
            'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter' => ConnectionAdapters::ActiveRecordAdapter,
            'PG::Connection' => ConnectionAdapters::PgAdapter
          }.freeze

          def initialize(connection)
            @connection_adapter = fetch_adapter(connection)
          end

          def current_schema
            connection_adapter.current_schema
          end

          def select_rows(sql, schemas = [])
            connection_adapter.select_rows(sql, schemas)
          end

          def exec_query(sql, schemas = [])
            connection_adapter.exec_query(sql, schemas)
          end

          private

          attr_reader :connection_adapter

          def fetch_adapter(connection)
            CONNECTION_ADAPTERS.fetch(connection.class.name).new(connection)
          rescue KeyError => e
            raise AdapterNotSupportedError, e.key
          end
        end
      end
    end
  end
end
