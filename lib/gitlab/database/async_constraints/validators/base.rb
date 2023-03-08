# frozen_string_literal: true

module Gitlab
  module Database
    module AsyncConstraints
      module Validators
        class Base
          include AsyncDdlExclusiveLeaseGuard
          extend ::Gitlab::Utils::Override

          TIMEOUT_PER_ACTION = 1.day
          STATEMENT_TIMEOUT = 12.hours

          def initialize(record)
            @record = record
          end

          def perform
            try_obtain_lease do
              if constraint_exists?
                log_info('Starting to validate constraint')
                validate_constraint_with_error_handling
                log_info('Finished validating constraint')
              else
                log_info(skip_log_message)
                record.destroy!
              end
            end
          end

          private

          attr_reader :record

          delegate :connection, :name, :table_name, :connection_db_config, to: :record

          def constraint_exists?; end

          def validate_constraint_with_error_handling
            validate_constraint
            record.destroy!
          rescue StandardError => error
            record.handle_exception!(error)

            Gitlab::ErrorTracking.track_and_raise_for_dev_exception(error)
            Gitlab::AppLogger.error(message: error.message, **logging_options)
          end

          def validate_constraint
            set_statement_timeout do
              connection.execute(<<~SQL.squish)
                ALTER TABLE #{connection.quote_table_name(table_name)}
                VALIDATE CONSTRAINT #{connection.quote_column_name(name)};
              SQL
            end
          end

          def set_statement_timeout
            connection.execute(format("SET statement_timeout TO '%ds'", STATEMENT_TIMEOUT))
            yield
          ensure
            connection.execute('RESET statement_timeout')
          end

          def lease_timeout
            TIMEOUT_PER_ACTION
          end

          def log_info(message)
            Gitlab::AppLogger.info(message: message, **logging_options)
          end

          def skip_log_message
            "Skipping #{name} validation since it does not exist. " \
              "The queuing entry will be deleted"
          end

          def logging_options
            {
              class: self.class.name.to_s,
              connection_name: database_config_name,
              constraint_name: name,
              constraint_type: record.constraint_type,
              table_name: table_name
            }
          end
        end
      end
    end
  end
end
