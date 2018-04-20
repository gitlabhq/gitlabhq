module Gitlab
  module OptimisticLocking
    module_function

    def retry_lock(subject, retries = 100, &block)
      ActiveRecord::Base.transaction do
        yield(subject)
      end
    rescue ActiveRecord::StaleObjectError
      retries -= 1
      raise unless retries >= 0

      subject.reload
      retry
    end

    alias_method :retry_optimistic_lock, :retry_lock
  end
end
