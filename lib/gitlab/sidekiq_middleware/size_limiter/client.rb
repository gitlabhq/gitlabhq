# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module SizeLimiter
      # This midleware is inserted into Sidekiq **client** middleware chain. It
      # prevents the caller from dispatching a too-large job payload. The job
      # payload should be small and simple. Read more at:
      # https://github.com/mperham/sidekiq/wiki/Best-Practices#1-make-your-job-parameters-small-and-simple
      class Client
        def call(worker_class, job, queue, _redis_pool)
          ::Gitlab::SidekiqMiddleware::SizeLimiter::Validator.validate!(worker_class, job)

          yield
        end
      end
    end
  end
end
