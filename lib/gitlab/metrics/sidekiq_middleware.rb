module Gitlab
  module Metrics
    # Sidekiq middleware for tracking jobs.
    #
    # This middleware is intended to be used as a server-side middleware.
    class SidekiqMiddleware
      def call(worker, message, queue)
        trans = BackgroundTransaction.new(worker.class)

        begin
          # Old gitlad-shell messages don't provide enqueued_at/created_at attributes
          trans.set(:sidekiq_queue_duration, Time.now.to_f - (message['enqueued_at'] || message['created_at'] || 0))
          trans.run { yield }
        rescue Exception => error # rubocop: disable Lint/RescueException
          trans.add_event(:sidekiq_exception)

          raise error
        ensure
          trans.finish
        end
      end
    end
  end
end
