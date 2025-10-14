# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module PreparedAsyncDmlOperationsTesting
        # This is a wrapper for Gitlab::Database::AsyncIndexes::IndexCreator, used to control the STATEMENT_TIMEOUT
        # and creating async indexes synchronously
        class IndexCreator < Gitlab::Database::AsyncIndexes::IndexCreator
          TIMEOUT_EXCEPTIONS = [ActiveRecord::StatementTimeout, ActiveRecord::AdapterTimeout,
            ActiveRecord::LockWaitTimeout, ActiveRecord::QueryCanceled].freeze

          def perform
            connection.transaction do
              execute_action
            end
          rescue *TIMEOUT_EXCEPTIONS => error
            Gitlab::AppLogger.info(message: error, index: async_index.name)
          ensure
            async_index.destroy!
          end

          private

          def execute_action
            connection.execute(format("SET statement_timeout TO '%ds'", 3.minutes))
            connection.execute(async_index.definition.gsub('CONCURRENTLY ', ''))
            connection.execute('RESET statement_timeout')
          end
        end
      end
    end
  end
end
