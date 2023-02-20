# frozen_string_literal: true

module Gitlab
  module Database
    module AsyncForeignKeys
      class ForeignKeyValidator
        include AsyncDdlExclusiveLeaseGuard

        TIMEOUT_PER_ACTION = 1.day
        STATEMENT_TIMEOUT = 12.hours

        def initialize(async_validation)
          @async_validation = async_validation
        end

        def perform
          try_obtain_lease do
            if foreign_key_exists?
              log_index_info("Starting to validate foreign key")
              validate_foreign_with_error_handling
              log_index_info("Finished validating foreign key")
            else
              log_index_info(skip_log_message)
              async_validation.destroy!
            end
          end
        end

        private

        attr_reader :async_validation

        delegate :connection, :name, :table_name, :connection_db_config, to: :async_validation

        def foreign_key_exists?
          relation = if table_name =~ Gitlab::Database::FULLY_QUALIFIED_IDENTIFIER
                       Gitlab::Database::PostgresForeignKey.by_constrained_table_identifier(table_name)
                     else
                       Gitlab::Database::PostgresForeignKey.by_constrained_table_name(table_name)
                     end

          relation.by_name(name).exists?
        end

        def validate_foreign_with_error_handling
          validate_foreign_key
          async_validation.destroy!
        rescue StandardError => error
          async_validation.handle_exception!(error)

          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(error)
          Gitlab::AppLogger.error(message: error.message, **logging_options)
        end

        def validate_foreign_key
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

        def log_index_info(message)
          Gitlab::AppLogger.info(message: message, **logging_options)
        end

        def skip_log_message
          "Skipping #{name} validation since it does not exist. " \
            "The queuing entry will be deleted"
        end

        def logging_options
          {
            fk_name: name,
            table_name: table_name,
            class: self.class.name.to_s
          }
        end
      end
    end
  end
end
