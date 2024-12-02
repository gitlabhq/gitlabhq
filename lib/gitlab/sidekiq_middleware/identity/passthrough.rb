# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module Identity
      class Passthrough
        include Sidekiq::ClientMiddleware

        def call(_worker_class, job, _queue, _redis_pool)
          ::Gitlab::Auth::Identity.currently_linked do |identity|
            identity.sidekiq_link!(job) if identity.composite?
          end

          yield
        end
      end
    end
  end
end
