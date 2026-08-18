# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    # Server-side Sidekiq middleware that populates ActiveSupport::ExecutionContext
    # with the current job hash so that ActiveRecord::QueryLogs can annotate SQL
    # queries with Sidekiq-specific context (jid, correlation_id, etc.).
    #
    # This replaces the Marginalia::SidekiqInstrumentation::Middleware that was
    # used previously.
    class QueryLogs
      def call(_worker, job, _queue)
        ActiveSupport::ExecutionContext[:job] = job
        yield
      ensure
        ActiveSupport::ExecutionContext[:job] = nil
      end
    end
  end
end
