# frozen_string_literal: true

module Gitlab
  module Database
    module AsyncIndexes
      class IndexDestructor
        include IndexingExclusiveLeaseGuard

        TIMEOUT_PER_ACTION = 1.day

        def initialize(async_index)
          @async_index = async_index
        end

        def perform
          try_obtain_lease do
            if !index_exists?
              log_index_info('Skipping dropping as the index does not exist')
            else
              log_index_info('Dropping async index')

              retries = Gitlab::Database::WithLockRetriesOutsideTransaction.new(
                connection: connection,
                timing_configuration: Gitlab::Database::Reindexing::REMOVE_INDEX_RETRY_CONFIG,
                klass: self.class,
                logger: Gitlab::AppLogger
              )

              retries.run(raise_on_exhaustion: false) do
                connection.execute(async_index.definition)
              end

              log_index_info('Finished dropping async index')
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

        def log_index_info(message)
          Gitlab::AppLogger.info(message: message, table_name: async_index.table_name, index_name: async_index.name)
        end
      end
    end
  end
end
