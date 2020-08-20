# frozen_string_literal: true

module Gitlab
  module Database
    class SchemaVersionFiles
      SCHEMA_DIRECTORY = 'db/schema_migrations'
      MIGRATION_DIRECTORIES = %w[db/migrate db/post_migrate].freeze
      MIGRATION_VERSION_GLOB = '20[0-9][0-9]*'

      def self.touch_all(versions_from_database)
        versions_from_migration_files = find_versions_from_migration_files

        version_filepaths = find_version_filenames.map { |f| schema_directory.join(f) }
        FileUtils.rm(version_filepaths)

        versions_to_create = versions_from_database & versions_from_migration_files
        versions_to_create.each do |version|
          version_filepath = schema_directory.join(version)

          File.open(version_filepath, 'w') do |file|
            file << Digest::SHA256.hexdigest(version)
          end
        end
      end

      def self.load_all
        version_filenames = find_version_filenames
        return if version_filenames.empty?

        values = version_filenames.map { |vf| "('#{connection.quote_string(vf)}')" }
        connection.execute(<<~SQL)
          INSERT INTO schema_migrations (version)
          VALUES #{values.join(',')}
          ON CONFLICT DO NOTHING
        SQL
      end

      def self.schema_directory
        @schema_directory ||= Rails.root.join(SCHEMA_DIRECTORY)
      end

      def self.migration_directories
        @migration_directories ||= MIGRATION_DIRECTORIES.map { |dir| Rails.root.join(dir) }
      end

      def self.find_version_filenames
        Dir.glob(MIGRATION_VERSION_GLOB, base: schema_directory)
      end

      def self.find_versions_from_migration_files
        migration_directories.each_with_object([]) do |directory, migration_versions|
          directory_migrations = Dir.glob(MIGRATION_VERSION_GLOB, base: directory)
          directory_versions = directory_migrations.map! { |m| m.split('_').first }

          migration_versions.concat(directory_versions)
        end
      end

      def self.connection
        ActiveRecord::Base.connection
      end
    end
  end
end
