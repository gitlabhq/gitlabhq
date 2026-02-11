# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module Identity
      class Passthrough
        include Sidekiq::ClientMiddleware

        def call(worker_class, job, _queue, _redis_pool)
          unless skip_composite_identity_passthrough?(worker_class)
            ::Gitlab::Auth::Identity.currently_linked do |identity|
              identity.sidekiq_link!(job) if identity.composite?
            end
          end

          yield
        end

        private

        def skip_composite_identity_passthrough?(worker_class)
          worker_class = worker_class.safe_constantize if worker_class.is_a?(String)
          return false unless worker_class

          worker_class.respond_to?(:skip_composite_identity_passthrough?) &&
            worker_class.skip_composite_identity_passthrough?
        end
      end
    end
  end
end
