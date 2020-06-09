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
          trans.set(:sidekiq_queue_duration, Time.current.to_f - enqueued_at)
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
        payload[:db_count] = trans.get(:db_count, :counter).to_i
        payload[:db_write_count] = trans.get(:db_write_count, :counter).to_i
        payload[:db_cached_count] = trans.get(:db_cached_count, :counter).to_i
      end
    end
  end
end
