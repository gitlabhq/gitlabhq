require 'yaml'

module Ci
  module Migrate
    class Database
      attr_reader :config

      def initialize
        @config = YAML.load_file(File.join(Rails.root, 'config', 'database.yml'))[Rails.env]
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
        abort 'Restore failed' unless success
      end

      protected

      def db_file_name
        File.join(Gitlab.config.backup.path, 'db', 'database.sql.gz')
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
