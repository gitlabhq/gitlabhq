# frozen_string_literal: true

module Gitlab
  module Database
    module AsyncIndexes
      class IndexBase
        include AsyncDdlExclusiveLeaseGuard
        extend ::Gitlab::Utils::Override

        TIMEOUT_PER_ACTION = 1.day

        def initialize(async_index)
          @async_index = async_index
        end

        def perform
          try_obtain_lease do
            if preconditions_met?
              log_index_info("Starting async index #{action_type}")
              execute_action_with_error_handling
              log_index_info("Finished async index #{action_type}")
            else
              log_index_info(skip_log_message)
              async_index.destroy!
            end
          end
        end

        private

        attr_reader :async_index

        delegate :connection, :connection_db_config, to: :async_index

        def preconditions_met?
          raise NotImplementedError, 'must implement preconditions_met?'
        end

        def action_type
          raise NotImplementedError, 'must implement action_type'
        end

        def execute_action_with_error_handling
          around_execution { execute_action }
        rescue StandardError => error
          async_index.handle_exception!(error)

          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(error)
          Gitlab::AppLogger.error(message: error.message, **logging_options)
        end

        def around_execution
          yield
        end

        def execute_action
          connection.execute(async_index.definition)
          async_index.destroy!
        end

        def index_exists?
          connection.indexes(async_index.table_name).any? do |index|
            index.name == async_index.name
          end
        end

        def lease_timeout
          TIMEOUT_PER_ACTION
        end

        def log_index_info(message)
          Gitlab::AppLogger.info(message: message, **logging_options)
        end

        def skip_log_message
          "Skipping index #{action_type} since preconditions are not met. " \
            "The queuing entry will be deleted"
        end

        def logging_options
          {
            table_name: async_index.table_name,
            index_name: async_index.name,
            class: self.class.name.to_s,
            connection_name: database_config_name
          }
        end
      end
    end
  end
end
