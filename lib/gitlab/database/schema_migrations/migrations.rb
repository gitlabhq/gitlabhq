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
          FileUtils.rm(version_filepaths)

          @context.versions_to_create.each do |version|
            version_filepath = File.join(schema_directory, version)

            File.open(version_filepath, 'w') do |file|
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
