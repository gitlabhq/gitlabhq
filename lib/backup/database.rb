require 'yaml'
require 'shellwords'

module Backup
  class Database
    attr_reader :config, :db_dir

    def initialize
      @config = YAML.load_file(File.join(Rails.root,'config','database.yml'))[Rails.env]
      @db_dir = File.join(Gitlab.config.backup.path, 'db')
      FileUtils.mkdir_p(@db_dir) unless Dir.exists?(@db_dir)
    end

    def dump
      case config["adapter"]
      when /^mysql/ then
        system("mysqldump #{mysql_args} #{Shellwords.shellescape(config['database'])} > #{Shellwords.shellescape(db_file_name)}")
      when "postgresql" then
        pg_env
        system("pg_dump #{Shellwords.shellescape(config['database'])} > #{db_file_name}")
      end
    end

    def restore
      case config["adapter"]
      when /^mysql/ then
        system("mysql #{mysql_args} #{Shellwords.shellescape(config['database'])} < #{db_file_name}")
      when "postgresql" then
        pg_env
        system("psql #{Shellwords.shellescape(config['database'])} -f #{Shellwords.shellescape(db_file_name)}")
      end
    end

    protected

    def db_file_name
      File.join(db_dir, 'database.sql')
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
      args.map { |opt, arg| "#{arg}=#{Shellwords.shellescape(config[opt])}" if config[opt] }.compact.join(' ')
    end

    def pg_env
      ENV['PGUSER']     = config["username"] if config["username"]
      ENV['PGHOST']     = config["host"] if config["host"]
      ENV['PGPORT']     = config["port"].to_s if config["port"]
      ENV['PGPASSWORD'] = config["password"].to_s if config["password"]
    end
  end
end
