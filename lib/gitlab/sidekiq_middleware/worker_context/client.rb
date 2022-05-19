# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module WorkerContext
      class Client
        include Gitlab::SidekiqMiddleware::WorkerContext

        def call(worker_class_or_name, job, _queue, _redis_pool, &block)
          worker_class = find_worker(worker_class_or_name.to_s.safe_constantize, job)

          # This is not a worker we know about, perhaps from a gem
          return yield unless worker_class
          return yield unless worker_class.respond_to?(:context_for_arguments)

          context_for_args = worker_class.context_for_arguments(job['args'])

          wrap_in_optional_context(context_for_args) do
            # This should be inside the context for the arguments so
            # that we don't override the feature category on the worker
            # with the one from the caller.

            root_caller_id = Gitlab::ApplicationContext.current_context_attribute(:root_caller_id) ||
              Gitlab::ApplicationContext.current_context_attribute(:caller_id)

            context = {
              root_caller_id: root_caller_id
            }

            # We do not want to set anything explicitly in the context
            # when the feature category is 'not_owned'.
            unless worker_class.feature_category_not_owned?
              context[:feature_category] = worker_class.get_feature_category.to_s
            end

            Gitlab::ApplicationContext.with_context(**context, &block)
          end
        end
      end
    end
  end
end
