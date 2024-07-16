# frozen_string_literal: true

module Gitlab
  module Database
    module Decomposition
      MigrateError = Class.new(RuntimeError)

      class Migrate
        TABLE_SIZE_QUERY = <<-SQL
          select sum(pg_table_size(concat(table_schema,'.',table_name))) as total
          from information_schema.tables
          where table_catalog = :table_catalog and table_type = 'BASE TABLE'
        SQL

        TABLE_COUNT_QUERY = <<-SQL
          select count(*) as total
          from information_schema.tables
          where table_catalog = :table_catalog and table_type = 'BASE TABLE'
          and table_schema not in ('information_schema', 'pg_catalog')
        SQL

        DISKSPACE_HEADROOM_FACTOR = 1.25

        attr_reader :backup_location

        def initialize(backup_base_location: nil)
          random_post_fix = SecureRandom.alphanumeric(10)
          @backup_base_location = backup_base_location || Gitlab.config.backup.path
          @backup_location = File.join(@backup_base_location, "migration_#{random_post_fix}")
        end

        def process!
          return unless can_migrate?

          dump_main_db
          import_dump_to_ci_db

          FileUtils.remove_entry_secure(@backup_location, true)
        end

        private

        def valid_backup_location?
          FileUtils.mkdir_p(@backup_base_location)

          true
        rescue StandardError => e
          raise MigrateError, "Failed to create directory #{@backup_base_location}: #{e.message}"
        end

        def main_table_sizes
          ApplicationRecord.connection.execute(
            ApplicationRecord.sanitize_sql([
              TABLE_SIZE_QUERY,
              { table_catalog: main_database_name }
            ])
          ).first["total"].to_f
        end

        def diskspace_free
          Sys::Filesystem.stat(
            File.expand_path("#{@backup_location}/../")
          ).bytes_free
        end

        def required_diskspace_available?
          needed = main_table_sizes * DISKSPACE_HEADROOM_FACTOR
          available = diskspace_free

          if needed > available
            raise MigrateError,
              "Not enough diskspace available on #{@backup_location}: " \
              "Available: #{ActiveSupport::NumberHelper.number_to_human_size(available)}, " \
              "Needed: #{ActiveSupport::NumberHelper.number_to_human_size(needed)}"
          end

          true
        end

        def single_database_setup?
          if Gitlab::Database.database_mode == Gitlab::Database::MODE_MULTIPLE_DATABASES
            raise MigrateError, "GitLab is already configured to run on multiple databases"
          end

          true
        end

        def ci_database_connect_ok?
          _, status = with_transient_pg_env(ci_config.pg_env_variables) do
            psql_args = ["--dbname=#{ci_database_name}", "-tAc", "select 1"]

            Open3.capture2e('psql', *psql_args)
          end

          unless status.success?
            raise MigrateError,
              "Can't connect to database '#{ci_database_name} on host '#{ci_config.pg_env_variables['PGHOST']}'. " \
              "Ensure the database has been created."
          end

          true
        end

        def ci_database_empty?
          sql = ApplicationRecord.sanitize_sql([
            TABLE_COUNT_QUERY,
            { table_catalog: ci_database_name }
          ])

          output, status = with_transient_pg_env(ci_config.pg_env_variables) do
            psql_args = ["--dbname=#{ci_database_name}", "-tAc", sql]

            Open3.capture2e('psql', *psql_args)
          end

          unless status.success? && output.chomp.to_i == 0
            raise MigrateError,
              "Database '#{ci_database_name}' is not empty"
          end

          true
        end

        def background_migrations_done?
          unfinished_count = Gitlab::Database::BackgroundMigration::BatchedMigration.unfinished.count
          if unfinished_count > 0
            raise MigrateError,
              "Found #{unfinished_count} unfinished background migration(s). Please wait until they are finished."
          end

          true
        end

        def can_migrate?
          valid_backup_location? &&
            single_database_setup? &&
            ci_database_connect_ok? &&
            ci_database_empty? &&
            required_diskspace_available? &&
            background_migrations_done?
        end

        def with_transient_pg_env(extended_env)
          ENV.merge!(extended_env)
          result = yield
          ENV.reject! { |k, _| extended_env.key?(k) }

          result
        end

        def import_dump_to_ci_db
          with_transient_pg_env(ci_config.pg_env_variables) do
            restore_args = ["--jobs=4", "--dbname=#{ci_database_name}"]

            Open3.capture2e('pg_restore', *restore_args, @backup_location)
          end
        end

        def dump_main_db
          with_transient_pg_env(main_config.pg_env_variables) do
            args = ['--format=d', '--jobs=4', "--file=#{@backup_location}"]

            Open3.capture2e('pg_dump', *args, main_database_name)
          end
        end

        def main_config
          @main_config ||= ::Backup::DatabaseConfiguration.new('main')
        end

        def ci_config
          @ci_config ||= ::Backup::DatabaseConfiguration.new('ci')
        end

        def main_database_name
          main_config.activerecord_configuration.database
        end

        def ci_database_name
          "#{main_config.activerecord_configuration.database}_ci"
        end
      end
    end
  end
end
