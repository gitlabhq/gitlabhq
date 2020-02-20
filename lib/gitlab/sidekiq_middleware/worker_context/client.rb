# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module WorkerContext
      class Client
        include Gitlab::SidekiqMiddleware::WorkerContext

        def call(worker_class_or_name, job, _queue, _redis_pool, &block)
          worker_class = worker_class_or_name.to_s.safe_constantize

          # Mailers can't be constantized like this
          return yield unless worker_class
          return yield unless worker_class.include?(::ApplicationWorker)

          context_for_args = worker_class.context_for_arguments(job['args'])

          wrap_in_optional_context(context_for_args, &block)
        end
      end
    end
  end
end
