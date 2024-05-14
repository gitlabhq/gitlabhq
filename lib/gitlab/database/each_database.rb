# frozen_string_literal: true

module Gitlab
  module Database
    module EachDatabase
      class << self
        def each_connection(only: nil, include_shared: true)
          selected_names = Array.wrap(only)
          base_models = select_base_models(selected_names)

          base_models.each_pair do |connection_name, model|
            next if !include_shared && Gitlab::Database.db_config_share_with(model.connection_db_config)

            connection = model.connection

            with_shared_connection(connection, connection_name) do
              yield connection, connection_name
            end
          end
        end

        def each_model_connection(models, only_on: nil, &blk)
          selected_databases = Array.wrap(only_on).map(&:to_sym)

          models.each do |model|
            # If model is shared, iterate all available base connections
            # Example: `LooseForeignKeys::DeletedRecord`
            if model < ::Gitlab::Database::SharedModel
              with_shared_model_connections(model, selected_databases, &blk)
            else
              with_model_connection(model, selected_databases, &blk)
            end
          end
        end

        private

        def select_base_models(names)
          base_models = Gitlab::Database.database_base_models_with_gitlab_shared
          return base_models if names.empty?

          names.each_with_object(HashWithIndifferentAccess.new) do |name, hash|
            raise ArgumentError, "#{name} is not a valid database name" unless base_models.key?(name)

            hash[name] = base_models[name]
          end
        end

        def with_shared_model_connections(shared_model, selected_databases, &blk)
          Gitlab::Database.database_base_models_with_gitlab_shared.each_pair do |connection_name, connection_model|
            if shared_model.limit_connection_names
              next unless shared_model.limit_connection_names.include?(connection_name.to_sym)
            end

            next if selected_databases.present? && selected_databases.exclude?(connection_name.to_sym)

            with_shared_connection(connection_model.connection, connection_name) do
              yield shared_model, connection_name
            end
          end
        end

        def with_model_connection(model, selected_databases, &blk)
          connection_name = model.connection_db_config.name

          return if selected_databases.present? && selected_databases.exclude?(connection_name.to_sym)

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
