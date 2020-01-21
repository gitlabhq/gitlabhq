# frozen_string_literal: true

module Gitlab
  module SidekiqLogging
    class ExceptionHandler
      def call(job_exception, context)
        data = {
          error_class: job_exception.class.name,
          error_message: job_exception.message
        }

        if context.is_a?(Hash)
          data.merge!(context)
          # correlation_id, jid, and class are available inside the job
          # Hash, so promote these arguments to the root tree so that
          # can be searched alongside other Sidekiq log messages.
          job_data = data.delete(:job)
          data.merge!(job_data) if job_data.present?
        end

        data[:error_backtrace] = Gitlab::BacktraceCleaner.clean_backtrace(job_exception.backtrace) if job_exception.backtrace.present?

        Sidekiq.logger.warn(data)
      end
    end
  end
end
