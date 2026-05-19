# frozen_string_literal: true

module ActiveContext
  class BulkProcessQueue
    def self.process!(queue, shard)
      new(queue, shard).process!
    end

    attr_reader :queue, :shard

    def initialize(queue, shard)
      @queue = queue
      @shard = shard
    end

    def process!
      ActiveContext::Redis.with_redis { |redis| process(redis) }
    end

    def process(redis)
      start_time = current_time
      specs_buffer = []
      scores = {}
      failures = []
      retryable = []

      collect_specs_from_queue(redis, specs_buffer, scores)

      return [0, 0] if specs_buffer.blank?

      refs = deserialize_all(specs_buffer)
      failures, retryable = process_refs(refs, failures, retryable)

      track_failures!(failures, retryable)
      cleanup_processed_refs(redis, scores, start_time, failures.count, retryable.count)

      [specs_buffer.count, failures.count]
    end

    private

    def collect_specs_from_queue(redis, specs_buffer, scores)
      queue.each_queued_items_by_shard(redis, shards: [shard]) do |shard_number, specs|
        next if specs.empty?

        set_key = queue.redis_set_key(shard_number)
        first_score = specs.first.last
        last_score = specs.last.last

        log_indexing_start(set_key, specs.count, first_score, last_score)

        specs_buffer.concat(specs)
        scores[set_key] = [first_score, last_score, specs.count]
      end
    end

    def process_refs(refs, failures, retryable)
      preprocess_result = Reference.preprocess_references(refs, **queue.preprocess_options)

      preprocess_result[:successful].each { |ref| bulk_processor.process(ref) }

      failures += preprocess_result[:failed]
      retryable += preprocess_result[:retryable]

      flushing_duration_s = Benchmark.realtime do
        failures += bulk_processor.flush
      end

      log_indexer_flushed(flushing_duration_s)

      [failures, retryable]
    end

    def cleanup_processed_refs(redis, scores, start_time, failures_count, retryable_count)
      scores.each do |set_key, (first_score, last_score, count)|
        redis.zremrangebyscore(set_key, first_score, last_score)
        log_indexing_end(set_key, count, first_score, last_score, failures_count, retryable_count, start_time)
      end
    end

    def log_indexing_start(set_key, refs_count, first_score, last_score)
      logger.info(
        'queue' => queue,
        'message' => 'bulk_indexing_start',
        'meta.indexing.redis_set' => set_key,
        'meta.indexing.refs_count' => refs_count,
        'meta.indexing.first_score' => first_score,
        'meta.indexing.last_score' => last_score
      )
    end

    def log_indexer_flushed(duration_s)
      logger.info(
        'class' => self.class.name,
        'message' => 'bulk_indexer_flushed',
        'meta.indexing.flushing_duration_s' => duration_s
      )
    end

    def log_indexing_end(set_key, count, first_score, last_score, failures_count, retryable_count, start_time)
      logger.info(
        'class' => self.class.name,
        'message' => 'bulk_indexing_end',
        'meta.indexing.redis_set' => set_key,
        'meta.indexing.refs_count' => count,
        'meta.indexing.first_score' => first_score,
        'meta.indexing.last_score' => last_score,
        'meta.indexing.failures_count' => failures_count,
        'meta.indexing.retryable_count' => retryable_count,
        'meta.indexing.bulk_execution_duration_s' => current_time - start_time
      )
    end

    def deserialize_all(specs)
      specs.filter_map { |spec, _| Reference.deserialize(spec) }
    end

    def bulk_processor
      @bulk_processor ||= ActiveContext::BulkProcessor.new
    end

    def logger
      @logger ||= ActiveContext::Config.logger
    end

    def current_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def track_failures!(failures, retryable)
      unless failures.empty?
        target_queue = queue == RetryQueue ? DeadQueue : RetryQueue
        ActiveContext.track!(failures, queue: target_queue)
      end

      return if retryable.empty?

      ActiveContext.track!(retryable, queue: queue)
    end
  end
end
