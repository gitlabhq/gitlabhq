# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    class CorrelationLogger
      def call(worker, job, queue)
        correlation_id = job[Gitlab::CorrelationId::LOG_KEY]

        Gitlab::CorrelationId.use_id(correlation_id) do
          yield
        end
      end
    end
  end
end
