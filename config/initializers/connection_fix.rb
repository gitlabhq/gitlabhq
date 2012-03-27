module ActiveRecord::ConnectionAdapters
  class MysqlAdapter
    alias_method :execute_without_retry, :execute

    def execute(*args)
      execute_without_retry(*args)
    rescue ActiveRecord::StatementInvalid => e
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
