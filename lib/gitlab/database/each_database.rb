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

        def each_model_connection(models, &blk)
          models.each do |model|
            # If model is shared, iterate all available base connections
            # Example: `LooseForeignKeys::DeletedRecord`
            if model < ::Gitlab::Database::SharedModel
              with_shared_model_connections(model, &blk)
            else
              with_model_connection(model, &blk)
            end
          end
        end

        private

        def with_shared_model_connections(shared_model, &blk)
          Gitlab::Database.database_base_models.each_pair do |connection_name, connection_model|
            if shared_model.limit_connection_names
              next unless shared_model.limit_connection_names.include?(connection_name.to_sym)
            end

            with_shared_connection(connection_model.connection, connection_name) do
              yield shared_model, connection_name
            end
          end
        end

        def with_model_connection(model, &blk)
          connection_name = model.connection.pool.db_config.name

          with_shared_connection(model.connection, connection_name) do
            yield model, connection_name
          end
        end

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
