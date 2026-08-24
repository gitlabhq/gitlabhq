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

      collect_specs_from_queue(redis, specs_buffer, scores)

      return [0, 0] if specs_buffer.blank?

      refs = deserialize_all(specs_buffer)
      failures = process_refs(refs, failures)

      track_failures!(failures)
      cleanup_processed_refs(redis, scores, start_time, failures.count)

      [specs_buffer.count, failures.count]
    end

    private

    def collect_specs_from_queue(redis, specs_buffer, scores)
      queue.each_queued_items_by_shard(redis, shards: [shard], due_only: true) do |shard_number, specs|
        next if specs.empty?

        set_key = queue.redis_set_key(shard_number)
        first_score = specs.first.last
        last_score = specs.last.last

        log_indexing_start(set_key, specs.count, first_score, last_score)

        specs_buffer.concat(specs)
        scores[set_key] = [first_score, last_score, specs.count]
      end
    end

    def process_refs(refs, failures)
      preprocess_result = Reference.preprocess_references(refs, **queue.preprocess_options)

      preprocess_result[:successful].each { |ref| bulk_processor.process(ref) }

      failures += preprocess_result[:failed]

      flushing_duration_s = Benchmark.realtime do
        failures += bulk_processor.flush
      end

      log_indexer_flushed(flushing_duration_s)

      failures
    end

    def cleanup_processed_refs(redis, scores, start_time, failures_count)
      scores.each do |set_key, (first_score, last_score, count)|
        redis.zremrangebyscore(set_key, first_score, last_score)
        log_indexing_end(set_key, count, first_score, last_score, failures_count, start_time)
      end
    end

    def log_indexing_start(set_key, refs_count, first_score, last_score)
      logger.info(
        'class_name' => self.class.name,
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
        'class_name' => self.class.name,
        'message' => 'bulk_indexer_flushed',
        'meta.indexing.flushing_duration_s' => duration_s
      )
    end

    def log_indexing_end(set_key, count, first_score, last_score, failures_count, start_time)
      duration_s = current_time - start_time

      duration_ms = duration_s.to_f * 1_000.to_f
      duration_per_ref_ms = duration_ms / count.to_f

      logger.info(
        'class_name' => self.class.name,
        'message' => 'bulk_indexing_end',
        'meta.indexing.redis_set' => set_key,
        'meta.indexing.refs_count' => count,
        'meta.indexing.first_score' => first_score,
        'meta.indexing.last_score' => last_score,
        'meta.indexing.failures_count' => failures_count,
        'meta.indexing.bulk_execution_duration_s' => duration_s,
        'meta.indexing.bulk_execution_duration_per_ref_ms' => duration_per_ref_ms
      )
    end

    def deserialize_all(specs)
      specs.filter_map { |spec, _| Reference.deserialize(spec) }
    end

    def bulk_processor
      @bulk_processor ||= ActiveContext::BulkProcessor.new(queue_name: queue.queue_name)
    end

    def logger
      @logger ||= ActiveContext::Config.logger
    end

    def current_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def track_failures!(failures)
      ActiveContext.track!(failures, queue: queue.failure_queue) unless failures.empty?
    end
  end
end
