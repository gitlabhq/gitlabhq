# frozen_string_literal: true

module Gitlab
  module OptimisticLocking
    MAX_RETRIES = 100

    module_function

    def retry_lock(subject, max_retries = MAX_RETRIES, name:, &block)
      start_time = Gitlab::Metrics::System.monotonic_time
      retry_attempts = 0

      begin
        ActiveRecord::Base.transaction do
          yield(subject)
        end
      rescue ActiveRecord::StaleObjectError
        raise unless retry_attempts < max_retries

        subject.reset

        retry_attempts += 1
        retry
      ensure
        elapsed_time = Gitlab::Metrics::System.monotonic_time - start_time

        log_optimistic_lock_retries(
          name: name,
          retry_attempts: retry_attempts,
          elapsed_time: elapsed_time)
      end
    end

    alias_method :retry_optimistic_lock, :retry_lock

    def log_optimistic_lock_retries(name:, retry_attempts:, elapsed_time:)
      return unless retry_attempts > 0

      retry_lock_logger.info(
        message: "Optimistic Lock released with retries",
        name: name,
        retries: retry_attempts,
        time_s: elapsed_time)
    end

    def retry_lock_logger
      @retry_lock_logger ||= Gitlab::Services::Logger.build
    end
  end
end
