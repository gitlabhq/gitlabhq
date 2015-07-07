require 'yaml'

module Backup
  class Database
    attr_reader :config, :db_dir

    def initialize
      @config = YAML.load_file(File.join(Rails.root,'config','database.yml'))[Rails.env]
      @db_dir = File.join(Gitlab.config.backup.path, 'db')
      FileUtils.mkdir_p(@db_dir) unless Dir.exists?(@db_dir)
    end

    def dump
      success = case config["adapter"]
      when /^mysql/ then
        $progress.print "Dumping MySQL database #{config['database']} ... "
        system('mysqldump', *mysql_args, config['database'], out: db_file_name)
      when "postgresql" then
        $progress.print "Dumping PostgreSQL database #{config['database']} ... "
        pg_env
        # Pass '--clean' to include 'DROP TABLE' statements in the DB dump.
        system('pg_dump', '--clean', config['database'], out: db_file_name)
      end
      report_success(success)
      abort 'Backup failed' unless success

      $progress.print 'Compressing database ... '
      success = system('gzip', db_file_name)
      report_success(success)
      abort 'Backup failed: compress error' unless success
    end

    def restore
      $progress.print 'Decompressing database ... '
      success = system('gzip', '-d', db_file_name_gz)
      report_success(success)
      abort 'Restore failed: decompress error' unless success

      success = case config["adapter"]
      when /^mysql/ then
        $progress.print "Restoring MySQL database #{config['database']} ... "
        system('mysql', *mysql_args, config['database'], in: db_file_name)
      when "postgresql" then
        $progress.print "Restoring PostgreSQL database #{config['database']} ... "
        pg_env
        system('psql', config['database'], '-f', db_file_name)
      end
      report_success(success)
      abort 'Restore failed' unless success
    end

    protected

    def db_file_name
      File.join(db_dir, 'database.sql')
    end

    def db_file_name_gz
      File.join(db_dir, 'database.sql.gz')
    end

    def mysql_args
      args = {
        'host'      => '--host',
        'port'      => '--port',
        'socket'    => '--socket',
        'username'  => '--user',
        'encoding'  => '--default-character-set',
        'password'  => '--password'
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
