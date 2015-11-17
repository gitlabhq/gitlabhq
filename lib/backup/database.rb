require 'yaml'

module Backup
  class Database
    attr_reader :config, :db_file_name

    def initialize
      @config = YAML.load_file(File.join(Rails.root,'config','database.yml'))[Rails.env]
      @db_file_name = File.join(Gitlab.config.backup.path, 'db', 'database.sql.gz')
    end

    def dump
      FileUtils.mkdir_p(File.dirname(db_file_name))
      FileUtils.rm_f(db_file_name)
      compress_rd, compress_wr = IO.pipe
      compress_pid = spawn(*%W(gzip -1 -c), in: compress_rd, out: [db_file_name, 'w', 0600])
      compress_rd.close

      dump_pid = case config["adapter"]
      when /^mysql/ then
        $progress.print "Dumping MySQL database #{config['database']} ... "
        # Workaround warnings from MySQL 5.6 about passwords on cmd line
        ENV['MYSQL_PWD'] = config["password"].to_s if config["password"]
        spawn('mysqldump', *mysql_args, config['database'], out: compress_wr)
      when "postgresql" then
        $progress.print "Dumping PostgreSQL database #{config['database']} ... "
        pg_env
        pgsql_args = ["--clean"] # Pass '--clean' to include 'DROP TABLE' statements in the DB dump.
        if Gitlab.config.backup.pg_schema
          pgsql_args << "-n"
          pgsql_args << Gitlab.config.backup.pg_schema
        end
        spawn('pg_dump', *pgsql_args, config['database'], out: compress_wr)
      end
      compress_wr.close

      success = [compress_pid, dump_pid].all? { |pid| Process.waitpid(pid); $?.success? }

      report_success(success)
      abort 'Backup failed' unless success
    end

    def restore
      decompress_rd, decompress_wr = IO.pipe
      decompress_pid = spawn(*%W(gzip -cd), out: decompress_wr, in: db_file_name)
      decompress_wr.close

      restore_pid = case config["adapter"]
      when /^mysql/ then
        $progress.print "Restoring MySQL database #{config['database']} ... "
        # Workaround warnings from MySQL 5.6 about passwords on cmd line
        ENV['MYSQL_PWD'] = config["password"].to_s if config["password"]
        spawn('mysql', *mysql_args, config['database'], in: decompress_rd)
      when "postgresql" then
        $progress.print "Restoring PostgreSQL database #{config['database']} ... "
        pg_env
        spawn('psql', config['database'], in: decompress_rd)
      end
      decompress_rd.close

      success = [decompress_pid, restore_pid].all? { |pid| Process.waitpid(pid); $?.success? }

      report_success(success)
      abort 'Restore failed' unless success
    end

    protected

    def mysql_args
      args = {
        'host'      => '--host',
        'port'      => '--port',
        'socket'    => '--socket',
        'username'  => '--user',
        'encoding'  => '--default-character-set'
      }
      args.map { |opt, arg| "#{arg}=#{config[opt]}" if config[opt] }.compact
    end

    def pg_env
      ENV['PGUSER']     = config["username"] if config["username"]
      ENV['PGHOST']     = config["host"] if config["host"]
      ENV['PGPORT']     = config["port"].to_s if config["port"]
      ENV['PGPASSWORD'] = config["password"].to_s if config["password"]
    end

    def report_success(success)
      if success
        $progress.puts '[DONE]'.green
      else
        $progress.puts '[FAILED]'.red
      end
    end
  end
end
