if defined?(ActiveRecord::ConnectionAdapters::Mysql2Adapter)
  module ActiveRecord::ConnectionAdapters
    class Mysql2Adapter
      alias_method :execute_without_retry, :execute

      def execute(*args)
        execute_without_retry(*args)
      rescue Mysql2::Error => e
        if e.message =~ /server has gone away/i
          warn "Server timed out, retrying"
          reconnect!
          retry
        else
          raise e
        end
      end
    end
  end
end