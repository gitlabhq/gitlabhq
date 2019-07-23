# frozen_string_literal: true

require 'yaml'

module Backup
  class Database
    include Backup::Helper
    attr_reader :progress
    attr_reader :config, :db_file_name

    def initialize(progress)
      @progress = progress
      @config = YAML.load_file(File.join(Rails.root, 'config', 'database.yml'))[Rails.env]
      @db_file_name = File.join(Gitlab.config.backup.path, 'db', 'database.sql.gz')
    end

    def dump
      FileUtils.mkdir_p(File.dirname(db_file_name))
      FileUtils.rm_f(db_file_name)
      compress_rd, compress_wr = IO.pipe
      compress_pid = spawn(gzip_cmd, in: compress_rd, out: [db_file_name, 'w', 0600])
      compress_rd.close

      dump_pid =
        case config["adapter"]
        when "postgresql" then
          progress.print "Dumping PostgreSQL database #{config['database']} ... "
          pg_env
          pgsql_args = ["--clean"] # Pass '--clean' to include 'DROP TABLE' statements in the DB dump.
          if Gitlab.config.backup.pg_schema
            pgsql_args << "-n"
            pgsql_args << Gitlab.config.backup.pg_schema
          end

          spawn('pg_dump', *pgsql_args, config['database'], out: compress_wr)
        end
      compress_wr.close

      success = [compress_pid, dump_pid].all? do |pid|
        Process.waitpid(pid)
        $?.success?
      end

      report_success(success)
      raise Backup::Error, 'Backup failed' unless success
    end

    def restore
      decompress_rd, decompress_wr = IO.pipe
      decompress_pid = spawn(*%w(gzip -cd), out: decompress_wr, in: db_file_name)
      decompress_wr.close

      restore_pid =
        case config["adapter"]
        when "postgresql" then
          progress.print "Restoring PostgreSQL database #{config['database']} ... "
          pg_env
          spawn('psql', config['database'], in: decompress_rd)
        end
      decompress_rd.close

      success = [decompress_pid, restore_pid].all? do |pid|
        Process.waitpid(pid)
        $?.success?
      end

      report_success(success)
      abort Backup::Error, 'Restore failed' unless success
    end

    protected

    def pg_env
      args = {
        'username'  => 'PGUSER',
        'host'      => 'PGHOST',
        'port'      => 'PGPORT',
        'password'  => 'PGPASSWORD',
        # SSL
        'sslmode'         => 'PGSSLMODE',
        'sslkey'          => 'PGSSLKEY',
        'sslcert'         => 'PGSSLCERT',
        'sslrootcert'     => 'PGSSLROOTCERT',
        'sslcrl'          => 'PGSSLCRL',
        'sslcompression'  => 'PGSSLCOMPRESSION'
      }
      args.each { |opt, arg| ENV[arg] = config[opt].to_s if config[opt] }
    end

    def report_success(success)
      if success
        progress.puts '[DONE]'.color(:green)
      else
        progress.puts '[FAILED]'.color(:red)
      end
    end
  end
end
