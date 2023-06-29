# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    class ArgumentsLogger
      include Sidekiq::ServerMiddleware

      def call(worker, job, queue)
        loggable_args = Gitlab::ErrorTracking::Processor::SidekiqProcessor.loggable_arguments(job['args'], job['class'])
        logger.info "arguments: #{Gitlab::Json.dump(loggable_args)}"
        yield
      end
    end
  end
end
