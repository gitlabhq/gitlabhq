# frozen_string_literal: true

module ActiveContext
  module Concerns
    module BulkAsyncProcess
      RESCHEDULE_INTERVAL = 1.second
      LOCK_TTL = 10.minutes
      LOCK_RETRIES = 10
      LOCK_SLEEP_SECONDS = 1

      extend ActiveSupport::Concern

      def perform(*args)
        unless ActiveContext::Config.indexing_enabled?
          log "#{self.class} indexing disabled. Execution is skipped."
          return false
        end

        if args.empty?
          enqueue_all_shards
        else
          queue_class, shard = args
          queue = queue_class.safe_constantize

          process_shard(queue, shard) if queue
        end
      rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
        # no-op, scheduled on a cronjob
      end

      def enqueue_all_shards
        self.class.bulk_perform_async_with_contexts(
          ActiveContext.raw_queues,
          arguments_proc: ->(raw_queue) { [raw_queue.class.to_s, raw_queue.shard] },
          context_proc: ->(_) { {} }
        )
      end

      def process_shard(queue, shard)
        in_lock(lock_key(queue, shard), ttl: LOCK_TTL, retries: LOCK_RETRIES, sleep_sec: LOCK_SLEEP_SECONDS) do
          BulkProcessQueue.process!(queue, shard).tap do |records_count, failures_count|
            log_extra_metadata_on_done(:records_count, records_count)
            log_extra_metadata_on_done(:shard_number, shard)

            re_enqueue_shard(queue, shard) if should_re_enqueue?(records_count, failures_count)
          end
        end
      end

      def re_enqueue_shard(queue, shard)
        self.class.perform_in(RESCHEDULE_INTERVAL, queue.to_s, shard)
      end

      def should_re_enqueue?(records_count, failures_count)
        return false if failures_count&.positive?
        return false unless records_count&.positive?

        ActiveContext::Config.re_enqueue_indexing_workers?
      end

      def log(message)
        logger.info(structured_payload(message: message))
      end

      def logger
        ActiveContext::Config.logger
      end

      def lock_key(queue, shard)
        "#{self.class.name.underscore}/queue/#{queue.redis_key}:#{shard}"
      end
    end
  end
end
