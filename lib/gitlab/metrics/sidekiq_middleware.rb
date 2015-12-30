module Gitlab
  module Metrics
    # Sidekiq middleware for tracking jobs.
    #
    # This middleware is intended to be used as a server-side middleware.
    class SidekiqMiddleware
      def call(worker, message, queue)
        trans = Transaction.new

        begin
          trans.run { yield }
        ensure
          tag_worker(trans, worker)
          trans.finish
        end
      end

      def tag_worker(trans, worker)
        trans.add_tag(:action, "#{worker.class.name}#perform")
      end
    end
  end
end
