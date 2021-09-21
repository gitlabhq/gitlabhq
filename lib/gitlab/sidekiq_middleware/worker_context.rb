# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module WorkerContext
      private

      def wrap_in_optional_context(context_or_nil, &block)
        return yield unless context_or_nil

        context_or_nil.use(&block)
      end

      def find_worker(worker_class, job)
        worker_name = (job['wrapped'].presence || worker_class).to_s

        Gitlab::SidekiqConfig::DEFAULT_WORKERS[worker_name]&.klass || worker_class
      end
    end
  end
end
