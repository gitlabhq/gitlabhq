# frozen_string_literal: true

require 'yaml'

module Backup
  class Database < Task
    extend ::Gitlab::Utils::Override
    include Backup::Helper
    attr_reader :force

    IGNORED_ERRORS = [
      # Ignore warnings
      /WARNING:/,
      # Ignore the DROP errors; recent database dumps will use --if-exists with pg_dump
      /does not exist$/,
      # User may not have permissions to drop extensions or schemas
      /must be owner of/
    ].freeze
    IGNORED_ERRORS_REGEXP = Regexp.union(IGNORED_ERRORS).freeze

    def initialize(progress, force:)
      super(progress)
      @force = force
    end

    override :dump
    def dump(destination_dir, backup_id)
      FileUtils.mkdir_p(destination_dir)

      each_database(destination_dir) do |database_name, current_db|
        model = current_db[:model]
        snapshot_id = current_db[:snapshot_id]

        pg_env = model.config[:pg_env]
        connection = model.connection
        active_record_config = model.config[:activerecord]
        pg_database = active_record_config[:database]

        db_file_name = file_name(destination_dir, database_name)
        FileUtils.rm_f(db_file_name)

        progress.print "Dumping PostgreSQL database #{pg_database} ... "

        pgsql_args = ["--clean"] # Pass '--clean' to include 'DROP TABLE' statements in the DB dump.
        pgsql_args << '--if-exists'
        pgsql_args << "--snapshot=#{snapshot_id}" if snapshot_id

        if Gitlab.config.backup.pg_schema
          pgsql_args << '-n'
          pgsql_args << Gitlab.config.backup.pg_schema

          Gitlab::Database::EXTRA_SCHEMAS.each do |schema|
            pgsql_args << '-n'
            pgsql_args << schema.to_s
          end
        end

        success = with_transient_pg_env(pg_env) do
          Backup::Dump::Postgres.new.dump(pg_database, db_file_name, pgsql_args)
        end

        connection.rollback_transaction if snapshot_id

        raise DatabaseBackupError.new(active_record_config, db_file_name) unless success

        report_success(success)
        progress.flush
      end
    ensure
      ::Gitlab::Database::EachDatabase.each_connection(
        only: base_models_for_backup.keys, include_shared: false
      ) do |connection, _|
        Gitlab::Database::TransactionTimeoutSettings.new(connection).restore_timeouts
      end
    end

    override :restore
    def restore(destination_dir)
      base_models_for_backup.each do |database_name, _base_model|
        backup_model = Backup::DatabaseModel.new(database_name)

        config = backup_model.config[:activerecord]

        db_file_name = file_name(destination_dir, database_name)
        database = config[:database]

        unless File.exist?(db_file_name)
          raise(Backup::Error, "Source database file does not exist #{db_file_name}") if main_database?(database_name)

          progress.puts "Source backup for the database #{database_name} doesn't exist. Skipping the task"
          return false
        end

        unless force
          progress.puts 'Removing all tables. Press `Ctrl-C` within 5 seconds to abort'.color(:yellow)
          sleep(5)
        end

        # Drop all tables Load the schema to ensure we don't have any newer tables
        # hanging out from a failed upgrade
        drop_tables(database_name)

        pg_env = backup_model.config[:pg_env]
        success = with_transient_pg_env(pg_env) do
          decompress_rd, decompress_wr = IO.pipe
          decompress_pid = spawn(*%w[gzip -cd], out: decompress_wr, in: db_file_name)
          decompress_wr.close

          status, @errors =
            case config[:adapter]
            when "postgresql" then
              progress.print "Restoring PostgreSQL database #{database} ... "
              execute_and_track_errors(pg_restore_cmd(database), decompress_rd)
            end
          decompress_rd.close

          Process.waitpid(decompress_pid)
          $?.success? && status.success?
        end

        if @errors.present?
          progress.print "------ BEGIN ERRORS -----\n".color(:yellow)
          progress.print @errors.join.color(:yellow)
          progress.print "------ END ERRORS -------\n".color(:yellow)
        end

        report_success(success)
        raise Backup::Error, 'Restore failed' unless success
      end
    end

    override :pre_restore_warning
    def pre_restore_warning
      return if force

      <<-MSG.strip_heredoc
        Be sure to stop Puma, Sidekiq, and any other process that
        connects to the database before proceeding. For Omnibus
        installs, see the following link for more information:
        https://docs.gitlab.com/ee/raketasks/backup_restore.html#restore-for-omnibus-gitlab-installations

        Before restoring the database, we will remove all existing
        tables to avoid future upgrade problems. Be aware that if you have
        custom tables in the GitLab database these tables and all data will be
        removed.
      MSG
    end

    override :post_restore_warning
    def post_restore_warning
      return unless @errors.present?

      <<-MSG.strip_heredoc
        There were errors in restoring the schema. This may cause
        issues if this results in missing indexes, constraints, or
        columns. Please record the errors above and contact GitLab
        Support if you have questions:
        https://about.gitlab.com/support/
      MSG
    end

    protected

    def base_models_for_backup
      @base_models_for_backup ||= Gitlab::Database.database_base_models_with_gitlab_shared
    end

    def main_database?(database_name)
      database_name.to_sym == :main
    end

    def file_name(base_dir, database_name)
      prefix = if database_name.to_sym != :main
                 "#{database_name}_"
               else
                 ''
               end

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
      if success
        progress.puts '[DONE]'.color(:green)
      else
        progress.puts '[FAILED]'.color(:red)
      end
    end

    private

    def drop_tables(database_name)
      puts_time 'Cleaning the database ... '.color(:blue)

      if Rake::Task.task_defined? "gitlab:db:drop_tables:#{database_name}"
        Rake::Task["gitlab:db:drop_tables:#{database_name}"].invoke
      else
        # In single database (single or two connections)
        Rake::Task["gitlab:db:drop_tables"].invoke
      end

      puts_time 'done'.color(:green)
    end

    def with_transient_pg_env(extended_env)
      ENV.merge!(extended_env)
      result = yield
      ENV.reject! { |k, _| extended_env.key?(k) }

      result
    end

    def pg_restore_cmd(database)
      ['psql', database]
    end

    def each_database(destination_dir, &block)
      databases = {}
      ::Gitlab::Database::EachDatabase.each_connection(
        only: base_models_for_backup.keys, include_shared: false
      ) do |_connection, name|
        next if databases[name]

        backup_model = Backup::DatabaseModel.new(name)

        databases[name] = {
          model: backup_model
        }

        next unless Gitlab::Database.database_mode == Gitlab::Database::MODE_MULTIPLE_DATABASES

        connection = backup_model.connection

        begin
          Gitlab::Database::TransactionTimeoutSettings.new(connection).disable_timeouts
          connection.begin_transaction(isolation: :repeatable_read)
          databases[name][:snapshot_id] = connection.select_value("SELECT pg_export_snapshot()")
        rescue ActiveRecord::ConnectionNotEstablished
          raise Backup::DatabaseBackupError.new(backup_model.config[:activerecord], file_name(destination_dir, name))
        end
      end

      databases.each(&block)
    end
  end
end
