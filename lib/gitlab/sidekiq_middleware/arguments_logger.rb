# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    class ArgumentsLogger
      include Sidekiq::ServerMiddleware

      def call(worker, job, queue)
        logger.info "arguments: #{Gitlab::Json.dump(job['args'])}"
        yield
      end
    end
  end
end
