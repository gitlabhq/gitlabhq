# frozen_string_literal: true

module Gitlab
  module Database
    module AsyncIndexes
      class IndexCreator
        include ExclusiveLeaseGuard

        TIMEOUT_PER_ACTION = 1.day
        STATEMENT_TIMEOUT = 20.hours

        def initialize(async_index)
          @async_index = async_index
        end

        def perform
          try_obtain_lease do
            if index_exists?
              log_index_info('Skipping index creation as the index exists')
            else
              log_index_info('Creating async index')

              set_statement_timeout do
                connection.execute(async_index.definition)
              end

              log_index_info('Finished creating async index')
            end

            async_index.destroy
          end
        end

        private

        attr_reader :async_index

        def index_exists?
          connection.indexes(async_index.table_name).any? { |index| index.name == async_index.name }
        end

        def connection
          @connection ||= async_index.connection
        end

        def lease_timeout
          TIMEOUT_PER_ACTION
        end

        def lease_key
          [super, async_index.connection_db_config.name].join('/')
        end

        def set_statement_timeout
          connection.execute("SET statement_timeout TO '%ds'" % STATEMENT_TIMEOUT)
          yield
        ensure
          connection.execute('RESET statement_timeout')
        end

        def log_index_info(message)
          Gitlab::AppLogger.info(message: message, table_name: async_index.table_name, index_name: async_index.name)
        end
      end
    end
  end
end
