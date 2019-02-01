# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    class CorrelationInjector
      def call(worker_class, job, queue, redis_pool)
        job[Gitlab::CorrelationId::LOG_KEY] ||=
          Gitlab::CorrelationId.current_or_new_id

        yield
      end
    end
  end
end
