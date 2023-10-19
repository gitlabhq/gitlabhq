# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    class ExtraDoneLogMetadata
      def call(worker, job, queue)
        yield
      ensure
        # We needed a way to pass state from a worker in to the
        # Gitlab::SidekiqLogging::StructuredLogger . Unfortunately the
        # StructuredLogger itself is not a middleware so cannot access the
        # worker object. We also tried to use SafeRequestStore but to pass the
        # data up but that doesn't work either because this is reset in
        # Gitlab::SidekiqMiddleware::RequestStoreMiddleware inside yield for
        # the StructuredLogger so it's cleared before we get to logging the
        # done statement. As such the only way to do this is to pass the data
        # up in the `job` object. Since `job` is just a Hash we can add this
        # extra metadata there.
        if worker.respond_to?(:logging_extras)
          job.merge!(worker.logging_extras)
        end
      end
    end
  end
end
