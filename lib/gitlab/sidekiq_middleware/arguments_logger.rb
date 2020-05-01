# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    class ArgumentsLogger
      def call(worker, job, queue)
        Sidekiq.logger.info "arguments: #{Gitlab::Json.dump(job['args'])}"
        yield
      end
    end
  end
end
