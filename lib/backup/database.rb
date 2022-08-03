# frozen_string_literal: true

require 'yaml'

module Backup
  class Database < Task
    extend ::Gitlab::Utils::Override
    include Backup::Helper
    attr_reader :force, :config

    IGNORED_ERRORS = [
      # Ignore warnings
      /WARNING:/,
      # Ignore the DROP errors; recent database dumps will use --if-exists with pg_dump
      /does not exist$/,
      # User may not have permissions to drop extensions or schemas
      /must be owner of/
    ].freeze
    IGNORED_ERRORS_REGEXP = Regexp.union(IGNORED_ERRORS).freeze

    def initialize(database_name, progress, force:)
      super(progress)
      @database_name = database_name
      @config = base_model.connection_db_config.configuration_hash
      @force = force
    end

    override :dump
    def dump(db_file_name, backup_id)
      FileUtils.mkdir_p(File.dirname(db_file_name))
      FileUtils.rm_f(db_file_name)
      compress_rd, compress_wr = IO.pipe
      compress_pid = spawn(gzip_cmd, in: compress_rd, out: [db_file_name, 'w', 0600])
      compress_rd.close

      dump_pid =
        case config[:adapter]
        when "postgresql" then
          progress.print "Dumping PostgreSQL database #{database} ... "
          pg_env
          pgsql_args = ["--clean"] # Pass '--clean' to include 'DROP TABLE' statements in the DB dump.
          pgsql_args << '--if-exists'

          if Gitlab.config.backup.pg_schema
            pgsql_args << '-n'
            pgsql_args << Gitlab.config.backup.pg_schema

            Gitlab::Database::EXTRA_SCHEMAS.each do |schema|
              pgsql_args << '-n'
              pgsql_args << schema.to_s
            end
          end

          Process.spawn('pg_dump', *pgsql_args, database, out: compress_wr)
        end
      compress_wr.close

      success = [compress_pid, dump_pid].all? do |pid|
        Process.waitpid(pid)
        $?.success?
      end

      report_success(success)
      progress.flush

      raise DatabaseBackupError.new(config, db_file_name) unless success
    end

    override :restore
    def restore(db_file_name)
      unless File.exist?(db_file_name)
        raise(Backup::Error, "Source database file does not exist #{db_file_name}") if main_database?

        progress.puts "Source backup for the database #{@database_name} doesn't exist. Skipping the task"
        return
      end

      unless force
        progress.puts 'Removing all tables. Press `Ctrl-C` within 5 seconds to abort'.color(:yellow)
        sleep(5)
      end

      # Drop all tables Load the schema to ensure we don't have any newer tables
      # hanging out from a failed upgrade
      puts_time 'Cleaning the database ... '.color(:blue)
      Rake::Task['gitlab:db:drop_tables'].invoke
      puts_time 'done'.color(:green)

      decompress_rd, decompress_wr = IO.pipe
      decompress_pid = spawn(*%w(gzip -cd), out: decompress_wr, in: db_file_name)
      decompress_wr.close

      status, @errors =
        case config[:adapter]
        when "postgresql" then
          progress.print "Restoring PostgreSQL database #{database} ... "
          pg_env
          execute_and_track_errors(pg_restore_cmd, decompress_rd)
        end
      decompress_rd.close

      Process.waitpid(decompress_pid)
      success = $?.success? && status.success?

      if @errors.present?
        progress.print "------ BEGIN ERRORS -----\n".color(:yellow)
        progress.print @errors.join.color(:yellow)
        progress.print "------ END ERRORS -------\n".color(:yellow)
      end

      report_success(success)
      raise Backup::Error, 'Restore failed' unless success
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

    def database
      @config[:database]
    end

    def base_model
      Gitlab::Database.database_base_models[@database_name]
    end

    def main_database?
      @database_name == :main
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

    def pg_env
      args = {
        username: 'PGUSER',
        host: 'PGHOST',
        port: 'PGPORT',
        password: 'PGPASSWORD',
        # SSL
        sslmode: 'PGSSLMODE',
        sslkey: 'PGSSLKEY',
        sslcert: 'PGSSLCERT',
        sslrootcert: 'PGSSLROOTCERT',
        sslcrl: 'PGSSLCRL',
        sslcompression: 'PGSSLCOMPRESSION'
      }
      args.each do |opt, arg|
        # This enables the use of different PostgreSQL settings in
        # case PgBouncer is used. PgBouncer clears the search path,
        # which wreaks havoc on Rails if connections are reused.
        override = "GITLAB_BACKUP_#{arg}"
        val = ENV[override].presence || config[opt].to_s.presence
        ENV[arg] = val if val
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

    def pg_restore_cmd
      ['psql', database]
    end
  end
end
