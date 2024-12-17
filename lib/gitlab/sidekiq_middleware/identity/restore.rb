# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module Identity
      class Restore
        include Sidekiq::ServerMiddleware

        def call(_worker, job, _queue)
          ::Gitlab::Auth::Identity.sidekiq_restore!(job)

          yield
        end
      end
    end
  end
end
