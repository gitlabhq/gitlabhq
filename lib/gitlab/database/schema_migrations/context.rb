# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaMigrations
      class Context
        attr_reader :connection

        def initialize(connection)
          @connection = connection
        end

        def schema_directory
          @schema_directory ||=
            if ActiveRecord::Base.configurations.primary?(database_name)
              File.join(db_dir, 'schema_migrations')
            else
              File.join(db_dir, "#{database_name}_schema_migrations")
            end
        end

        def versions_to_create
          versions_from_database = @connection.schema_migration.all_versions
          versions_from_migration_files = @connection.migration_context.migrations.map { |m| m.version.to_s }

          versions_from_database & versions_from_migration_files
        end

        private

        def database_name
          @database_name ||= @connection.pool.db_config.name
        end

        def db_dir
          @db_dir ||= Rails.application.config.paths["db"].first
        end
      end
    end
  end
end
