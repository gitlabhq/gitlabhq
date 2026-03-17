# frozen_string_literal: true

require 'yaml'

module Backup
  module Targets
    class Database < Target
      include ::Gitlab::Utils::StrongMemoize

      extend ::Gitlab::Utils::Override
      include Backup::Helper

      attr_reader :force, :errors, :logger

      IGNORED_ERRORS = [
        # Ignore warnings
        /WARNING:/,
        # Ignore the DROP errors; recent database dumps will use --if-exists with pg_dump
        /does not exist$/,
        # User may not have permissions to drop extensions or schemas
        /must be owner of/,
        # PG16 introduced generally ignorable error `must be able to SET ROLE "gitlab-psql"`
        /must be able to SET ROLE "gitlab-psql"/i
      ].freeze
      IGNORED_ERRORS_REGEXP = Regexp.union(IGNORED_ERRORS).freeze

      def initialize(progress, options:)
        super(progress, options: options)

        @errors = []
        @force = options.force?
        @logger = Gitlab::BackupLogger.new(progress)
      end

      override :dump

      def dump(destination_dir, _)
        FileUtils.mkdir_p(destination_dir)

        each_database(destination_dir, additional_connections: additional_connections_config) do |backup_connection|
          pg_env = backup_connection.database_configuration.pg_env_variables
          active_record_config = backup_connection.database_configuration.activerecord_variables
          pg_database_name = active_record_config[:database]

          dump_file_name = file_name(destination_dir, backup_connection.connection_name)
          FileUtils.rm_f(dump_file_name)

          logger.info "Dumping PostgreSQL database #{pg_database_name} ... "

          schemas = []

          if Gitlab.config.backup.pg_schema
            schemas << Gitlab.config.backup.pg_schema
            schemas.push(*Gitlab::Database::EXTRA_SCHEMAS.map(&:to_s))
          end

          pg_dump = ::Gitlab::Backup::Cli::Utils::PgDump.new(
            database_name: pg_database_name,
            snapshot_id: backup_connection.snapshot_id,
            schemas: schemas,
            env: pg_env)

          success = Backup::Dump::Postgres.new.dump(dump_file_name, pg_dump)

          backup_connection.release_snapshot! if backup_connection.snapshot_id

          raise DatabaseBackupError.new(active_record_config, dump_file_name) unless success

          report_success(success)
          logger.flush
        end
      ensure
        if multiple_databases?
          ::Gitlab::Database::EachDatabase.each_connection(
            only: base_models_for_backup.keys, include_shared: false
          ) do |_, database_connection_name|
            backup_connection = Backup::DatabaseConnection.new(database_connection_name)
            backup_connection.restore_timeouts!
          rescue ActiveRecord::ConnectionNotEstablished
            raise Backup::DatabaseBackupError.new(
              backup_connection.database_configuration.activerecord_variables,
              file_name(destination_dir, database_connection_name)
            )
          end
        end
      end

      override :restore

      def restore(destination_dir, _)
        @errors = []

        base_models_for_backup.each do |database_name, _|
          backup_connection = Backup::DatabaseConnection.new(database_name)

          config = backup_connection.database_configuration.activerecord_variables

          db_file_name = file_name(destination_dir, database_name)
          do_restore(backup_connection, config, db_file_name)
        end

        additional_connections_config.each do |connection|
          do_restore(connection, connection.database_configuration.activerecord_variables,
            file_name(destination_dir, connection.connection_name))
        end
      end

      def do_restore(backup_connection, config, db_file_name)
        database = config[:database]
        database_name = backup_connection.connection_name

        unless File.exist?(db_file_name)
          raise(Backup::Error, "Source database file does not exist #{db_file_name}") if main_database?(database_name)

          logger.info "Source backup for the database #{database_name} doesn't exist. Skipping the task"
          return false
        end

        logger.info "Restoring PostgreSQL database #{database_name} ... "

        unless force
          logger.info 'Removing all tables. Press `Ctrl-C` within 5 seconds to abort'
          sleep(5)
        end

        # Drop all tables Load the schema to ensure we don't have any newer tables
        # hanging out from a failed upgrade
        #
        begin
          drop_tables(database_name, backup_connection)
        rescue ActiveRecord::StatementInvalid => asi
          raise unless asi.message.include?('PG::InsufficientPrivilege')

          logger.error "Not enough database permissions for the #{database_name} database."
          logger.error "Please check the user credentials"
          report_success(false)
          return
        end

        tracked_errors = []
        pg_env = backup_connection.database_configuration.pg_env_variables
        success = with_transient_pg_env(pg_env) do
          decompress_rd, decompress_wr = IO.pipe
          decompress_pid = spawn(decompress_cmd, out: decompress_wr, in: db_file_name)
          decompress_wr.close

          logger.info "Restoring the database ..."
          status, tracked_errors = execute_and_track_errors(pg_restore_cmd(database), decompress_rd)
          decompress_rd.close

          Process.waitpid(decompress_pid)
          $?.success? && status.success?
        end

        unless tracked_errors.empty?
          logger.error "------ BEGIN ERRORS -----\n"
          logger.error tracked_errors.join
          logger.error "------ END ERRORS -------\n"

          @errors += tracked_errors
        end

        report_success(success)
        raise Backup::Error, 'Restore failed' unless success
      end

      protected

      def base_models_for_backup
        @base_models_for_backup ||= Gitlab::Database.database_base_models_with_gitlab_shared
      end

      def main_database?(database_name)
        database_name.to_sym == :main
      end

      def file_name(base_dir, database_name)
        prefix = database_name.to_sym != :main ? "#{database_name}_" : ''

        File.join(base_dir, "#{prefix}database.sql.gz")
      end

      def ignore_error?(line)
        IGNORED_ERRORS_REGEXP.match?(line)
      end

      def execute_and_track_errors(cmd, decompress_rd)
        errors = []

        Open3.popen3(ENV, *cmd) do |stdin, stdout, stderr, thread|
          stdin.binmode

          out_reader = Thread.new do
            data = stdout.read
            $stdout.write(data)
          end

          err_reader = Thread.new do
            until (raw_line = stderr.gets).nil?
              warn(raw_line)
              errors << raw_line unless ignore_error?(raw_line)
            end
          end

          begin
            IO.copy_stream(decompress_rd, stdin)
          rescue Errno::EPIPE
          end

          stdin.close
          [thread, out_reader, err_reader].each(&:join)
          [thread.value, errors]
        end
      end

      def report_success(success)
        success ? logger.info('[DONE]') : logger.error('[FAILED]')
      end

      private

      def include_additional_connections?
        include_registry_db?
      end

      def registry_db_base_keys
        %w[HOST PORT NAME SSLMODE CONNECT_TIMEOUT USER].map { |x| "REGISTRY_DATABASE_#{x}" }
      end

      # Registry backup is enabled when credentials (PASSWORD, SSL certs) are provided,
      # in addition to basic connection info (HOST, PORT, NAME, USER).
      # The presence of ONLY base connection keys means backup is not fully configured.
      def include_registry_db?
        (ENV.keys.select { |x| x.start_with?('REGISTRY_DATABASE_') } - registry_db_base_keys).present?
      end

      def drop_tables(database_name, connection)
        logger.info 'Cleaning the database ... '

        if Rake::Task.task_defined? "gitlab:db:drop_tables:#{database_name}"
          Rake::Task["gitlab:db:drop_tables:#{database_name}"].invoke
        elsif !additional_connections_config.select { |x| x.connection_name == database_name }.empty?
          drop_tables_for_additional_connection(connection)
        else
          # In single database (single or two connections)
          Rake::Task["gitlab:db:drop_tables"].invoke
        end

        logger.info 'done'
      end

      def drop_tables_for_additional_connection(backup_connection)
        logger.info "Cleaning the database #{backup_connection.connection_name} ... "

        connection = backup_connection.connection
        # Get all tables in the public schema
        # Drop all tables
        backup_connection.tables.each do |table|
          connection.execute("DROP TABLE IF EXISTS #{connection.quote_table_name(table)} CASCADE")
        end

        ## Triggers/functions
        backup_connection.functions.each do |function|
          connection.execute("DROP FUNCTION IF EXISTS #{connection.quote_table_name(function)}")
        end

        logger.info 'done'
      rescue ActiveRecord::StatementInvalid => asi
        raise unless asi.cause.is_a?(PG::ServerError)

        logger.warn "There was an error dropping objects in #{backup_connection.connection_name}: #{asi.message}"
      end

      # @deprecated This will be removed when restore operation is refactored to use extended_env directly
      def with_transient_pg_env(extended_env)
        ENV.merge!(extended_env)
        result = yield
        ENV.reject! { |k, _| extended_env.key?(k) }

        result
      end

      def pg_restore_cmd(database)
        ['psql', database]
      end

      def registry_database_env(field)
        ENV.fetch("REGISTRY_DATABASE_#{field.upcase}", nil)
      end

      def registry_db_connection
        registry_db_config = {
          adapter: 'postgresql',
          database: registry_database_env('name'),
          username: registry_database_env('user'),
          password: registry_database_env('password'),
          host: registry_database_env('host'),
          port: registry_database_env('port'),
          sslmode: registry_database_env('sslmode'),
          sslcert: registry_database_env('sslcert'),
          sslkey: registry_database_env('sslkey'),
          sslrootcert: registry_database_env('rootcert'),
          connect_timeout: registry_database_env('connect_timeout')
        }

        db_connection = Backup::DatabaseConnection.new(
          'registry',
          custom_config: registry_db_config
        )
        begin
          db_connection.connection.postgresql_version
        rescue ActiveRecord::DatabaseConnectionError => dce
          raise Backup::Error,
            "Unable to connect to the registry database with the provided information: #{dce.message}"
        end
        db_connection
      end

      def additional_connections_config
        return [] unless include_additional_connections?

        [registry_db_connection]
      end
      strong_memoize_attr :additional_connections_config

      def each_database(destination_dir, additional_connections: [], &block)
        databases = []

        # each connection will loop through all database connections defined in `database.yml`
        # and reject the ones that are shared, so we don't get duplicates
        #
        # we consider a connection to be shared when it has `database_tasks: false`
        ::Gitlab::Database::EachDatabase.each_connection(
          only: base_models_for_backup.keys, include_shared: false
        ) do |_, database_connection_name|
          backup_connection = Backup::DatabaseConnection.new(database_connection_name)
          databases << backup_connection

          next unless multiple_databases?

          begin
            # Trigger a transaction snapshot export that will be used by pg_dump later on
            backup_connection.export_snapshot!
          rescue ActiveRecord::ConnectionNotEstablished
            raise Backup::DatabaseBackupError.new(
              backup_connection.database_configuration.activerecord_variables,
              file_name(destination_dir, database_connection_name)
            )
          end
        end

        # Add arbitrary database connections that are not configured via Rails
        # Note: We don't export snapshots for custom connections because:
        # 1. They are typically on different database clusters
        # 2. Snapshots are only valid within the same PostgreSQL cluster
        # 3. Cross-database snapshot consistency is not needed for external databases
        additional_connections.each do |connection|
          databases << connection
        end

        databases.each(&block)
      end

      def multiple_databases?
        Gitlab::Database.database_mode == Gitlab::Database::MODE_MULTIPLE_DATABASES
      end
    end
  end
end
