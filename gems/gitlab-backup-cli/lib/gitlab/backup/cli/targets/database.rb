# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Targets
        class Database < Target
          # Owner can read/write, group no permission, others no permission
          FILE_PERMISSION = 0o600

          IGNORED_ERRORS = [
            # Ignore warnings
            /WARNING:/,
            # Ignore the DROP errors; recent database dumps will use --if-exists with pg_dump
            /does not exist$/,
            # User may not have permissions to drop extensions or schemas
            /must be owner of/
          ].freeze
          IGNORED_ERRORS_REGEXP = Regexp.union(IGNORED_ERRORS).freeze

          attr_reader :errors

          def initialize(context)
            super(context)

            @errors = []
          end

          def dump(destination_dir)
            FileUtils.mkdir_p(destination_dir)

            postgres = Gitlab::Backup::Cli::Services::Postgres.new(context)

            # Phase 1: trigger snapshot generation (quick)
            postgres.each do |database|
              dump_file_name = file_name(destination_dir, database)

              database.export_snapshot!
            rescue ActiveRecord::ConnectionNotEstablished
              raise Errors::DatabaseBackupError.new(database.connection_params, dump_file_name)
            end

            # Phase 2: Run PgDump based on snapshot_id (slow)
            postgres.each do |database| # rubocop:disable Style/CombinableLoops -- export needs to happen first
              pg_database_name = database.configuration.database
              dump_file_name = file_name(destination_dir, database)

              Gitlab::Backup::Cli::Output.print_info("Dumping PostgreSQL database #{pg_database_name} ... ")

              status = database_dump(database: database, filepath: dump_file_name)
              report_finish_status(status.success?)

              unless errors.empty?
                Gitlab::Backup::Cli::Output.error "------ BEGIN ERRORS -----"
                Gitlab::Backup::Cli::Output.print(errors.join, stderr: true)
                Gitlab::Backup::Cli::Output.error "------ END ERRORS -------"
              end

              raise Errors::DatabaseBackupError.new(database.connection_params, dump_file_name) unless status.success?
            ensure
              database.release_snapshot!
              database.restore_timeouts!
            end
          end

          def restore(source)
            databases = Gitlab::Backup::Cli::Services::Postgres.new(context)

            databases.each do |db|
              database_name = db.configuration.name
              pg_database_name = db.configuration.database
              db_file_name = file_name(source, db)

              Gitlab::Backup::Cli::Output.info("Restoring #{database_name} database ... ")

              unless db_file_name.exist?
                failure_info = "Database backup file '#{db_file_name}' for the #{database_name} database does not exist"

                if main_database?(db)
                  Gitlab::Backup::Cli::Output.print_tag(:failure)

                  raise Gitlab::Backup::Cli::Error, failure_info
                end

                Gitlab::Backup::Cli::Output.print_tag(:skipped)

                Gitlab::Backup::Cli::Output.warning(failure_info)

                next
              end

              # Drop all tables Load the schema to ensure we don't have any newer tables
              # hanging out from a failed upgrade
              drop_tables(db)

              Gitlab::Backup::Cli::Output.info "Restoring PostgreSQL database #{pg_database_name} ... "

              status = restore_tables(database: db, filepath: db_file_name)
              report_finish_status(status.success?)

              unless errors.empty?
                Gitlab::Backup::Cli::Output.error "------ BEGIN ERRORS -----"
                Gitlab::Backup::Cli::Output.print(errors.join, stderr: true)
                Gitlab::Backup::Cli::Output.error "------ END ERRORS -------"
              end

              unless status.success?
                raise Gitlab::Backup::Cli::Errors::DatabaseRestoreError.new(database.connection_params, db_file_name)
              end
            end
          end

          protected

          def main_database?(database)
            database.configuration.name.to_sym == :main
          end

          def file_name(base_dir, database)
            prefix = main_database?(database) ? '' : "#{database.configuration.name}_"

            Pathname.new(File.join(base_dir, "#{prefix}database.sql.gz"))
          end

          def ignore_error?(line)
            IGNORED_ERRORS_REGEXP.match?(line)
          end

          private

          def database_dump(database:, filepath:)
            pg_env = database.pg_env_variables
            pg_database_name = database.configuration.database

            pg_dump = ::Gitlab::Backup::Cli::Utils::PgDump.new(
              database_name: pg_database_name,
              snapshot_id: database.snapshot_id,
              env: pg_env).build_command

            pipeline = Gitlab::Backup::Cli::Shell::Pipeline.new(
              pg_dump,
              Utils::Compression.compression_command
            )

            pipeline.run!(output: [filepath, 'w', FILE_PERMISSION]).tap do |status|
              @errors = status.stderr
            end
          end

          def report_finish_status(status)
            Gitlab::Backup::Cli::Output.print_tag(status ? :success : :failure)
          end

          def drop_tables(database)
            pg_database_name = database.configuration.database
            Gitlab::Backup::Cli::Output.print_info "Cleaning the '#{pg_database_name}' database ... "

            if Rake::Task.task_defined? "gitlab:db:drop_tables:#{database.configuration.name}"
              Rake::Task["gitlab:db:drop_tables:#{database.configuration.name}"].invoke
            else
              # In single database (single or two connections)
              Rake::Task["gitlab:db:drop_tables"].invoke
            end

            Gitlab::Backup::Cli::Output.print_tag(:success)
          end

          def restore_tables(database:, filepath:)
            pipeline = Gitlab::Backup::Cli::Shell::Pipeline.new(
              Utils::Compression.decompression_command,
              pg_restore_cmd(database)
            )

            pipeline.run!(input: filepath).tap do |status|
              @errors = status.stderr
            end
          end

          def pg_restore_cmd(database)
            Shell::Command.new('psql', database.configuration.database, env: database.pg_env_variables)
          end
        end
      end
    end
  end
end
