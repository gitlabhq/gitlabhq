module Gitlab
  module Metrics
    # Sidekiq middleware for tracking jobs.
    #
    # This middleware is intended to be used as a server-side middleware.
    class SidekiqMiddleware
      def call(worker, message, queue)
        trans = Transaction.new("#{worker.class.name}#perform")

        begin
          trans.run { yield }
        ensure
          trans.finish
        end
      end
    end
  end
end
