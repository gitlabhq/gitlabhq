# frozen_string_literal: true

module Gitlab
  module Metrics
    # Sidekiq middleware for tracking jobs.
    #
    # This middleware is intended to be used as a server-side middleware.
    class SidekiqMiddleware
      def call(worker, payload, queue)
        trans = BackgroundTransaction.new(worker.class)

        begin
          # Old gitlad-shell messages don't provide enqueued_at/created_at attributes
          enqueued_at = payload['enqueued_at'] || payload['created_at'] || 0
          trans.set(:gitlab_transaction_sidekiq_queue_duration_total, Time.current.to_f - enqueued_at) do
            multiprocess_mode :livesum
          end
          trans.run { yield }
        rescue Exception => error # rubocop: disable Lint/RescueException
          trans.add_event(:sidekiq_exception)

          raise error
        ensure
          add_info_to_payload(payload, trans)
        end
      end

      private

      def add_info_to_payload(payload, trans)
        payload.merge!(::Gitlab::Metrics::Subscribers::ActiveRecord.db_counter_payload)
      end
    end
  end
end
