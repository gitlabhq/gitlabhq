# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      class Runner
        BASE_RESULT_DIR = Rails.root.join('tmp', 'migration-testing').freeze
        METADATA_FILENAME = 'metadata.json'
        SCHEMA_VERSION = 4 # Version of the output format produced by the runner
        POST_MIGRATION_MATCHER = %r{db/post_migrate/}

        class << self
          def up(database:, legacy_mode: false)
            within_context_for_database(database) do
              Runner.new(direction: :up, database: database, migrations: migrations_for_up(database), legacy_mode: legacy_mode)
            end
          end

          def down(database:, legacy_mode: false)
            within_context_for_database(database) do
              Runner.new(direction: :down, database: database, migrations: migrations_for_down(database), legacy_mode: legacy_mode)
            end
          end

          def background_migrations
            TestBackgroundRunner.new(result_dir: BASE_RESULT_DIR.join('background_migrations'))
          end

          def batched_background_migrations(for_database:, legacy_mode: false)
            runner = nil

            result_dir = background_migrations_dir(for_database, legacy_mode)

            # Only one loop iteration since we pass `only:` here
            Gitlab::Database::EachDatabase.each_connection(only: for_database) do |connection|
              from_id = batched_migrations_last_id(for_database).read

              runner = Gitlab::Database::Migrations::TestBatchedBackgroundRunner
                         .new(result_dir: result_dir, connection: connection, from_id: from_id)
            end

            runner
          end

          def migration_context
            # We're mirroring rails internal migration code, which requires that
            # ActiveRecord::Base has connected to the current database. The correct database is chosen by
            # within_context_for_database
            ActiveRecord::Base.connection.migration_context # rubocop:disable Database/MultipleDatabases
          end

          # rubocop:disable Database/MultipleDatabases
          def within_context_for_database(database)
            original_db_config = ActiveRecord::Base.connection_db_config
            # The config only works if passed a string
            db_config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: database.to_s)
            raise ArgumentError, "Cannot find a database configuration for #{database}" unless db_config

            ActiveRecord::Base.establish_connection(db_config) # rubocop:disable Database/EstablishConnection

            yield
          ensure
            ActiveRecord::Base.establish_connection(original_db_config) # rubocop:disable Database/EstablishConnection
          end
          # rubocop:enable Database/MultipleDatabases

          def batched_migrations_last_id(for_database)
            runner = nil
            base_dir = background_migrations_dir(for_database, false)

            Gitlab::Database::EachDatabase.each_connection(only: for_database) do |connection|
              runner = Gitlab::Database::Migrations::BatchedMigrationLastId
                         .new(connection, base_dir)
            end

            runner
          end

          private

          def migrations_for_up(database)
            existing_versions = migration_context.get_all_versions.to_set

            migration_context.migrations.reject do |migration|
              existing_versions.include?(migration.version)
            end
          end

          def migration_file_names_this_branch
            `git diff --name-only origin/HEAD...HEAD db/post_migrate db/migrate`.split("\n")
          end

          def migrations_for_down(database)
            versions_this_branch = migration_file_names_this_branch.map do |m_name|
              m_name.match(%r{^db/(post_)?migrate/(\d+)}) { |m| m.captures[1]&.to_i }
            end.to_set

            existing_versions = migration_context.get_all_versions.to_set
            migration_context.migrations.select do |migration|
              existing_versions.include?(migration.version) && versions_this_branch.include?(migration.version)
            end
          end

          def background_migrations_dir(db, legacy_mode)
            return BASE_RESULT_DIR.join('background_migrations') if legacy_mode

            BASE_RESULT_DIR.join(db.to_s, 'background_migrations')
          end
        end

        attr_reader :direction, :result_dir, :migrations

        delegate :migration_context, :within_context_for_database, to: :class

        def initialize(direction:, database:, migrations:, legacy_mode: false)
          raise "Direction must be up or down" unless %i[up down].include?(direction)

          @direction = direction
          @migrations = migrations
          @result_dir = if legacy_mode
                          BASE_RESULT_DIR.join(direction.to_s)
                        else
                          BASE_RESULT_DIR.join(database.to_s, direction.to_s)
                        end

          @database = database
          @legacy_mode = legacy_mode
        end

        def run
          FileUtils.mkdir_p(result_dir)

          verbose_was = ActiveRecord::Migration.verbose
          ActiveRecord::Migration.verbose = true

          sorted_migrations = migrations.sort_by do |m|
            [m.filename.match?(POST_MIGRATION_MATCHER) ? 1 : 0, m.version]
          end

          sorted_migrations.reverse! if direction == :down

          instrumentation = Instrumentation.new(result_dir: result_dir)

          within_context_for_database(@database) do
            sorted_migrations.each do |migration|
              instrumentation.observe(version: migration.version, name: migration.name, connection: ActiveRecord::Migration.connection) do
                ActiveRecord::Migrator.new(direction, migration_context.migrations, migration_context.schema_migration, migration.version).run
              end
            end
          end
        ensure
          metadata_filename = File.join(result_dir, METADATA_FILENAME)
          version = if @legacy_mode
                      3
                    else
                      SCHEMA_VERSION
                    end

          File.write(metadata_filename, { database: @database.to_s, version: version }.to_json)

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
