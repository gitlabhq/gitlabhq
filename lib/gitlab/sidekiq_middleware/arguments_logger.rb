module Gitlab
  module SidekiqMiddleware
    class ArgumentsLogger
      def call(worker, job, queue)
        Sidekiq.logger.info "arguments: #{job['args']}"
        yield
      end
    end
  end
end
