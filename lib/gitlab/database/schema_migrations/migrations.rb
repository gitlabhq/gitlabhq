# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaMigrations
      class Migrations
        MIGRATION_VERSION_GLOB = '20[0-9][0-9]*'

        def initialize(context)
          @context = context
        end

        def touch_all
          return unless @context.versions_to_create.any?

          version_filepaths = version_filenames.map { |f| File.join(schema_directory, f) }

          version_filepaths.each do |version_filepath|
            FileUtils.rm(version_filepath) if File.exist?(version_filepath) && File.writable?(version_filepath)
          end

          @context.versions_to_create.each do |version|
            path = File.join(schema_directory, version)

            next unless File.exist?(path) ? File.writable?(path) : File.writable?(File.dirname(path))

            File.open(path, 'w') do |file|
              file << Digest::SHA256.hexdigest(version)
            end
          end
        end

        def load_all
          return if version_filenames.empty?

          values = version_filenames.map { |vf| "('#{@context.connection.quote_string(vf)}')" }

          @context.connection.execute(<<~SQL)
          INSERT INTO schema_migrations (version)
          VALUES #{values.join(',')}
          ON CONFLICT DO NOTHING
          SQL
        end

        private

        def schema_directory
          @context.schema_directory
        end

        def version_filenames
          @version_filenames ||= Dir.glob(MIGRATION_VERSION_GLOB, base: schema_directory)
        end
      end
    end
  end
end
