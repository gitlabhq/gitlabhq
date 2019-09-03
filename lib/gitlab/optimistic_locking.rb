# frozen_string_literal: true

module Gitlab
  module OptimisticLocking
    module_function

    def retry_lock(subject, retries = nil, &block)
      retries ||= 100
      # TODO(Observability): We should be recording details of the number of retries and the duration of the total execution here
      ActiveRecord::Base.transaction do
        yield(subject)
      end
    rescue ActiveRecord::StaleObjectError
      retries -= 1
      raise unless retries >= 0

      subject.reset
      retry
    end

    alias_method :retry_optimistic_lock, :retry_lock
  end
end
