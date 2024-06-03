# frozen_string_literal: true

module Gitlab
  module QueryLimiting
    # Middleware for reporting (or raising) when a Sidekiq worker performs more than a
    # certain amount of database queries.
    class SidekiqMiddleware
      def call(worker, _job, _queue)
        transaction, retval = ::Gitlab::QueryLimiting::Transaction.run do
          yield
        end

        transaction.action = action_name(worker)
        transaction.act_upon_results

        retval
      end

      private

      def action_name(worker)
        worker.class.name
      end
    end
  end
end
