# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module ConcurrencyLimit
      class WorkersConcurrency
        class << self
          CACHE_EXPIRES_IN = 5.seconds

          def current_for(worker:, skip_cache: false)
            worker_class = worker.is_a?(Class) ? worker : worker.class
            worker_name = worker_class.name

            workers(skip_cache: skip_cache)[worker_name].to_i
          end

          def workers(skip_cache: false)
            return workers_uncached if skip_cache

            Rails.cache.fetch(self.class.name, expires_in: CACHE_EXPIRES_IN) do
              workers_uncached
            end
          end

          private

          def workers_uncached
            sidekiq_workers.map { |_process_id, _thread_id, work| ::Gitlab::Json.parse(work['payload'])['class'] }.tally
          end

          def sidekiq_workers
            Sidekiq::Workers.new.each
          end
        end
      end
    end
  end
end
