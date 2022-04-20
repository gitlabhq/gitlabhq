# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      class Runner
        BASE_RESULT_DIR = Rails.root.join('tmp', 'migration-testing').freeze
        METADATA_FILENAME = 'metadata.json'
        SCHEMA_VERSION = 3 # Version of the output format produced by the runner

        class << self
          def up
            Runner.new(direction: :up, migrations: migrations_for_up, result_dir: BASE_RESULT_DIR.join('up'))
          end

          def down
            Runner.new(direction: :down, migrations: migrations_for_down, result_dir: BASE_RESULT_DIR.join('down'))
          end

          def background_migrations
            TestBackgroundRunner.new(result_dir: BASE_RESULT_DIR.join('background_migrations'))
          end

          def migration_context
            @migration_context ||= ApplicationRecord.connection.migration_context
          end

          private

          def migrations_for_up
            existing_versions = migration_context.get_all_versions.to_set

            migration_context.migrations.reject do |migration|
              existing_versions.include?(migration.version)
            end
          end

          def migration_file_names_this_branch
            `git diff --name-only origin/HEAD...HEAD db/post_migrate db/migrate`.split("\n")
          end

          def migrations_for_down
            versions_this_branch = migration_file_names_this_branch.map do |m_name|
              m_name.match(%r{^db/(post_)?migrate/(\d+)}) { |m| m.captures[1]&.to_i }
            end.to_set

            existing_versions = migration_context.get_all_versions.to_set
            migration_context.migrations.select do |migration|
              existing_versions.include?(migration.version) && versions_this_branch.include?(migration.version)
            end
          end
        end

        attr_reader :direction, :result_dir, :migrations

        delegate :migration_context, to: :class

        def initialize(direction:, migrations:, result_dir:)
          raise "Direction must be up or down" unless %i[up down].include?(direction)

          @direction = direction
          @migrations = migrations
          @result_dir = result_dir
        end

        def run
          FileUtils.mkdir_p(result_dir)

          verbose_was = ActiveRecord::Migration.verbose
          ActiveRecord::Migration.verbose = true

          sorted_migrations = migrations.sort_by(&:version)
          sorted_migrations.reverse! if direction == :down

          instrumentation = Instrumentation.new(result_dir: result_dir)

          sorted_migrations.each do |migration|
            instrumentation.observe(version: migration.version, name: migration.name, connection: ActiveRecord::Migration.connection) do
              ActiveRecord::Migrator.new(direction, migration_context.migrations, migration_context.schema_migration, migration.version).run
            end
          end
        ensure
          metadata_filename = File.join(result_dir, METADATA_FILENAME)
          File.write(metadata_filename, { version: SCHEMA_VERSION }.to_json)

          # We clear the cache here to mirror the cache clearing that happens at the end of `db:migrate` tasks
          # This clearing makes subsequent rake tasks in the same execution pick up database schema changes caused by
          # the migrations that were just executed
          ApplicationRecord.clear_cache!
          ActiveRecord::Migration.verbose = verbose_was
        end
      end
    end
  end
end
