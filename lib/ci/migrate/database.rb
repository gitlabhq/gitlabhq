require 'yaml'

module Ci
  module Migrate
    class Database
      attr_reader :config

      def initialize
        @config = YAML.load_file(File.join(Rails.root, 'config', 'database.yml'))[Rails.env]
      end

      def restore(ci_dump)
        puts 'Deleting all CI related data ... '
        truncate_ci_tables

        puts 'Restoring CI data ... '
        case config["adapter"]
          when /^mysql/ then
            print "Restoring MySQL database #{config['database']} ... "
            # Workaround warnings from MySQL 5.6 about passwords on cmd line
            ENV['MYSQL_PWD'] = config["password"].to_s if config["password"]
            system('mysql', *mysql_args, config['database'], in: ci_dump)
          when "postgresql" then
            puts "Restoring PostgreSQL database #{config['database']} ... "
            pg_env
            system('psql', config['database'], '-f', ci_dump)
        end
      end

      protected

      def truncate_ci_tables
        c = ActiveRecord::Base.connection
        c.tables.select { |t| t.start_with?('ci_') }.each do |table|
          puts "Deleting data from #{table}..."
          c.execute("DELETE FROM #{table}")
        end
      end

      def mysql_args
        args = {
          'host' => '--host',
          'port' => '--port',
          'socket' => '--socket',
          'username' => '--user',
          'encoding' => '--default-character-set'
        }
        args.map { |opt, arg| "#{arg}=#{config[opt]}" if config[opt] }.compact
      end

      def pg_env
        ENV['PGUSER'] = config["username"] if config["username"]
        ENV['PGHOST'] = config["host"] if config["host"]
        ENV['PGPORT'] = config["port"].to_s if config["port"]
        ENV['PGPASSWORD'] = config["password"].to_s if config["password"]
      end

      def report_success(success)
        if success
          puts '[DONE]'.green
        else
          puts '[FAILED]'.red
        end
      end
    end
  end
end
