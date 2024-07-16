# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module DuplicateJobs
      module Strategies
        class Base
          include ::Gitlab::ExclusiveLeaseHelpers

          DEFAULT_LOCK_KEY_TTL = 5.seconds
          MAX_RETRIES = 10
          LOCK_RETRY_SLEEP = 0.05.seconds

          def initialize(duplicate_job)
            @duplicate_job = duplicate_job
          end

          def schedule(job)
            raise NotImplementedError
          end

          def perform(_job)
            raise NotImplementedError
          end

          private

          attr_reader :duplicate_job

          def strategy_name
            self.class.name.to_s.demodulize.underscore.humanize.downcase
          end

          def check!
            # The default expiry time is the worker class'
            # configured deduplication TTL or DuplicateJob::DEFAULT_DUPLICATE_KEY_TTL.
            duplicate_job.check!
          end

          def dedup_lock_key
            "duplicate_job:#{duplicate_job.idempotency_key}:lock:v1"
          end

          def with_dedup_lock
            return yield unless @duplicate_job.strategy == :until_executed && @duplicate_job.reschedulable?
            return yield unless Feature.enabled?(:use_sidekiq_dedup_lock, type: :beta) # rubocop:disable Gitlab/FeatureFlagWithoutActor -- global flags

            in_lock(dedup_lock_key, ttl: DEFAULT_LOCK_KEY_TTL, retries: MAX_RETRIES, sleep_sec: LOCK_RETRY_SLEEP) do
              yield
            end
          end
        end
      end
    end
  end
end
