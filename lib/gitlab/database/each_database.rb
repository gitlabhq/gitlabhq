# frozen_string_literal: true

module Gitlab
  module Database
    module EachDatabase
      class << self
        def each_database_connection
          Gitlab::Database.database_base_models.each_pair do |connection_name, model|
            connection = model.connection

            with_shared_connection(connection, connection_name) do
              yield connection, connection_name
            end
          end
        end

        def each_model_connection(models)
          models.each do |model|
            connection_name = model.connection.pool.db_config.name

            with_shared_connection(model.connection, connection_name) do
              yield model, connection_name
            end
          end
        end

        private

        def with_shared_connection(connection, connection_name)
          Gitlab::Database::SharedModel.using_connection(connection) do
            Gitlab::AppLogger.debug(message: 'Switched database connection', connection_name: connection_name)

            yield
          end
        end
      end
    end
  end
end
