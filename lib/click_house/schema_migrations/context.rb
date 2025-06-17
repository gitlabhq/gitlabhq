# frozen_string_literal: true

module ClickHouse
  module SchemaMigrations
    class Context
      attr_reader :connection, :database

      class_attribute :default_schema_migrations_path, default: 'db/click_house/schema_migrations'

      def initialize(connection, database)
        @connection = connection
        @database = database
      end

      def schema_directory
        @schema_directory ||= Rails.root.join(default_schema_migrations_path, database.to_s).to_s
      end

      def versions_to_create
        return [] if Rails.env.test?

        schema_migration = ClickHouse::MigrationSupport::SchemaMigration.new(connection)

        schema_migration.all_versions
      end

      def current_schema_migration_files
        return [] unless File.directory?(schema_directory)

        Dir.glob('*', base: schema_directory)
      end
    end
  end
end
