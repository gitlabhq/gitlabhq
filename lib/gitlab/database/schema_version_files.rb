# frozen_string_literal: true

module Gitlab
  module Database
    class SchemaVersionFiles
      SCHEMA_DIRECTORY = "db/schema_migrations"

      def self.touch_all(versions)
        filenames_with_path = find_version_filenames.map { |f| schema_dirpath.join(f) }
        FileUtils.rm(filenames_with_path)

        versions.each do |version|
          version_filepath = schema_dirpath.join(version)

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
          VALUES #{values.join(",")}
          ON CONFLICT DO NOTHING
        SQL
      end

      def self.schema_dirpath
        @schema_dirpath ||= Rails.root.join(SCHEMA_DIRECTORY)
      end

      def self.find_version_filenames
        Dir.glob("20[0-9][0-9]*", base: schema_dirpath)
      end

      def self.connection
        ActiveRecord::Base.connection
      end
    end
  end
end
