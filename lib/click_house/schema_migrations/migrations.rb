# frozen_string_literal: true

module ClickHouse
  module SchemaMigrations
    class Migrations < Gitlab::Database::SchemaMigrations::Migrations
      def load_all
        return if version_filenames.empty?

        schema_migration = ClickHouse::MigrationSupport::SchemaMigration.new(@context.connection)
        schema_migration.ensure_table

        version_filenames.each do |version|
          schema_migration.create!(version: version.to_s)
        end
      end
    end
  end
end
