# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    class InstrumentationLogger
      def call(worker, job, queue)
        ::Gitlab::InstrumentationHelper.init_instrumentation_data

        yield

      ensure
        # The Sidekiq logger is called outside the middleware block, so
        # we need to modify the job hash to pass along this information
        # since RequestStore is only active in the Sidekiq middleware.
        #
        # Modifying the job hash in a middleware is permitted by Sidekiq
        # because Sidekiq keeps a pristine copy of the original hash
        # before sending it to the middleware:
        # https://github.com/mperham/sidekiq/blob/53bd529a0c3f901879925b8390353129c465b1f2/lib/sidekiq/processor.rb#L115-L118
        job[:instrumentation] = {}.tap do |instrumentation_values|
          ::Gitlab::InstrumentationHelper.add_instrumentation_data(instrumentation_values)
        end
      end
    end
  end
end
