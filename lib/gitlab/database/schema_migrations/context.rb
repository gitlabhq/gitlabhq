# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaMigrations
      class Context
        attr_reader :connection

        class_attribute :default_schema_migrations_path, default: 'db/schema_migrations'

        def initialize(connection)
          @connection = connection
        end

        def schema_directory
          @schema_directory ||= Rails.root.join(database_schema_migrations_path).to_s
        end

        def versions_to_create
          versions_from_database =
            if ::Gitlab.next_rails?
              @connection.schema_migration.versions
            else
              @connection.schema_migration.all_versions
            end

          versions_from_migration_files = @connection.migration_context.migrations.map { |m| m.version.to_s }

          versions_from_database & versions_from_migration_files
        end

        private

        def database_name
          @database_name ||= @connection.pool.db_config.name
        end

        def database_schema_migrations_path
          @connection.pool.db_config.configuration_hash[:schema_migrations_path] || self.class.default_schema_migrations_path
        end
      end
    end
  end
end
