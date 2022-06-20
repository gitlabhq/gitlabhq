# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module WorkerContext
      class Server
        include Gitlab::SidekiqMiddleware::WorkerContext

        def call(worker, job, _queue, &block)
          worker_class = find_worker(worker.class, job)

          # This is not a worker we know about, perhaps from a gem
          return yield unless worker_class.respond_to?(:get_worker_context)

          feature_category = worker_class.get_feature_category.to_s

          Gitlab::ApplicationContext.with_context(feature_category: feature_category) do
            # Use the context defined on the class level as the more specific context
            wrap_in_optional_context(worker_class.get_worker_context, &block)
          end
        end
      end
    end
  end
end
