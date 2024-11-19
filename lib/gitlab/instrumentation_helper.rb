# frozen_string_literal: true

module Gitlab
  module InstrumentationHelper
    extend self

    DURATION_PRECISION = 6 # microseconds

    def init_instrumentation_data
      Gitlab::RequestContext.start_thread_context
    end

    def add_instrumentation_data(payload)
      instrument_gitaly(payload)
      instrument_redis(payload)
      instrument_elasticsearch(payload)
      instrument_zoekt(payload)
      instrument_throttle(payload)
      instrument_active_record(payload)
      instrument_external_http(payload)
      instrument_rack_attack(payload)
      instrument_middleware_path_traversal_check(payload)
      instrument_cpu(payload)
      instrument_thread_memory_allocations(payload)
      instrument_load_balancing(payload)
      instrument_pid(payload)
      instrument_worker_id(payload)
      instrument_uploads(payload)
      instrument_rate_limiting_gates(payload)
      instrument_global_search_api(payload)
      instrument_ldap(payload)
      instrument_exclusive_lock(payload)
    end

    def instrument_gitaly(payload)
      gitaly_calls = Gitlab::GitalyClient.get_request_count

      return if gitaly_calls == 0

      payload[:gitaly_calls] = gitaly_calls
      payload[:gitaly_duration_s] = Gitlab::GitalyClient.query_time
    end

    def instrument_redis(payload)
      payload.merge! ::Gitlab::Instrumentation::Redis.payload
    end

    def instrument_elasticsearch(payload)
      # Elasticsearch integration is only available in EE but instrumentation
      # only depends on the Gem which is also available in FOSS.
      elasticsearch_calls = Gitlab::Instrumentation::ElasticsearchTransport.get_request_count

      return if elasticsearch_calls == 0

      payload[:elasticsearch_calls] = elasticsearch_calls
      payload[:elasticsearch_duration_s] = Gitlab::Instrumentation::ElasticsearchTransport.query_time
      payload[:elasticsearch_timed_out_count] = Gitlab::Instrumentation::ElasticsearchTransport.get_timed_out_count
    end

    def instrument_zoekt(payload)
      # Zoekt integration is only available in EE but instrumentation
      # only depends on the Gem which is also available in FOSS.
      zoekt_calls = Gitlab::Instrumentation::Zoekt.get_request_count

      return if zoekt_calls == 0

      payload[:zoekt_calls] = zoekt_calls
      payload[:zoekt_duration_s] = Gitlab::Instrumentation::Zoekt.query_time
    end

    def instrument_external_http(payload)
      external_http_count = Gitlab::Metrics::Subscribers::ExternalHttp.request_count

      return if external_http_count == 0

      payload.merge! Gitlab::Metrics::Subscribers::ExternalHttp.payload
    end

    def instrument_throttle(payload)
      safelist = Gitlab::Instrumentation::Throttle.safelist
      payload[:throttle_safelist] = safelist if safelist.present?
    end

    def instrument_active_record(payload)
      db_counters = ::Gitlab::Metrics::Subscribers::ActiveRecord.db_counter_payload

      payload.merge!(db_counters)
    end

    def instrument_rack_attack(payload)
      rack_attack_redis_count = ::Gitlab::Metrics::Subscribers::RackAttack.payload[:rack_attack_redis_count]
      return if rack_attack_redis_count == 0

      payload.merge!(::Gitlab::Metrics::Subscribers::RackAttack.payload)
    end

    def instrument_cpu(payload)
      cpu_s = ::Gitlab::Metrics::System.thread_cpu_duration(
        ::Gitlab::RequestContext.instance.start_thread_cpu_time)

      payload[:cpu_s] = cpu_s.round(DURATION_PRECISION) if cpu_s
    end

    def instrument_pid(payload)
      payload[:pid] = Process.pid
    end

    def instrument_worker_id(payload)
      payload[:worker_id] = ::Prometheus::PidProvider.worker_id
    end

    def instrument_thread_memory_allocations(payload)
      counters = ::Gitlab::Memory::Instrumentation.measure_thread_memory_allocations(
        ::Gitlab::RequestContext.instance.thread_memory_allocations)
      payload.merge!(counters) if counters
    end

    def instrument_load_balancing(payload)
      load_balancing_payload = ::Gitlab::Metrics::Subscribers::LoadBalancing.load_balancing_payload

      payload.merge!(load_balancing_payload)
    end

    def instrument_uploads(payload)
      payload.merge! ::Gitlab::Instrumentation::Uploads.payload
    end

    def instrument_rate_limiting_gates(payload)
      payload.merge!(::Gitlab::Instrumentation::RateLimitingGates.payload)
    end

    def instrument_global_search_api(payload)
      payload.merge!(::Gitlab::Instrumentation::GlobalSearchApi.payload)
    end

    def instrument_ldap(payload)
      ldap_count = Gitlab::Metrics::Subscribers::Ldap.count

      return if ldap_count == 0

      payload.merge! Gitlab::Metrics::Subscribers::Ldap.payload
    end

    def instrument_exclusive_lock(payload)
      requested_count = Gitlab::Instrumentation::ExclusiveLock.requested_count

      return if requested_count == 0

      payload.merge!(Gitlab::Instrumentation::ExclusiveLock.payload)
    end

    def instrument_middleware_path_traversal_check(payload)
      duration = ::Gitlab::Instrumentation::Middleware::PathTraversalCheck.duration

      return if duration == 0

      payload.merge!(::Gitlab::Instrumentation::Middleware::PathTraversalCheck.payload)
    end

    # Returns the queuing duration for a Sidekiq job in seconds, as a float, if the
    # `enqueued_at` field or `created_at` field is available.
    #
    # * If the job doesn't contain sufficient information, returns nil
    # * If the job has a start time in the future, returns 0
    # * If the job contains an invalid start time value, returns nil
    # @param [Hash] job a Sidekiq job, represented as a hash
    def self.queue_duration_for_job(job)
      # Old gitlab-shell messages don't provide enqueued_at/created_at attributes
      enqueued_at = job['enqueued_at'] || job['created_at']
      return unless enqueued_at

      enqueued_at_time = convert_to_time(enqueued_at)
      return unless enqueued_at_time

      round_elapsed_time(enqueued_at_time)
    end

    # Returns the buffering duration for a Sidekiq job in seconds, as a float, if the
    # `concurrency_limit_buffered_at` field is available.
    #
    # * If the job doesn't contain sufficient information, returns nil
    # * If the job has a start time in the future, returns 0
    # * If the job contains an invalid start time value, returns nil
    # @param [Hash] job a Sidekiq job, represented as a hash
    def self.buffering_duration_for_job(job)
      buffered_at = job['concurrency_limit_buffered_at']
      return unless buffered_at

      buffered_at_time = convert_to_time(buffered_at)
      return unless buffered_at_time

      round_elapsed_time(buffered_at_time)
    end

    # Returns the time it took for a scheduled job to be enqueued in seconds, as a float,
    # if the `scheduled_at` and `enqueued_at` fields are available.
    #
    # * If the job doesn't contain sufficient information, returns nil
    # * If the job has a start time in the future, returns 0
    # * If the job contains an invalid start time value, returns nil
    # @param [Hash] job a Sidekiq job, represented as a hash
    def self.enqueue_latency_for_scheduled_job(job)
      scheduled_at = job['scheduled_at']
      enqueued_at = job['enqueued_at']

      return unless scheduled_at && enqueued_at

      scheduled_at_time = convert_to_time(scheduled_at)
      enqueued_at_time = convert_to_time(enqueued_at)

      return unless scheduled_at_time && enqueued_at_time

      round_elapsed_time(scheduled_at_time, enqueued_at_time)
    end

    def self.round_elapsed_time(start, end_time = Time.now)
      # It's possible that if there is clock-skew between two nodes this
      # value may be less than zero. In that event, we record the value
      # as zero.
      [elapsed_by_absolute_time(start, end_time), 0].max.round(DURATION_PRECISION)
    end

    # Calculates the time in seconds, as a float, from
    # the provided start time until now
    #
    # @param [Time] start
    def self.elapsed_by_absolute_time(start, end_time)
      (end_time - start).to_f.round(DURATION_PRECISION)
    end
    private_class_method :elapsed_by_absolute_time

    # Convert a representation of a time into a `Time` value
    #
    # @param time_value String, Float time representation, or nil
    def self.convert_to_time(time_value)
      return time_value if time_value.is_a?(Time)
      return Time.iso8601(time_value) if time_value.is_a?(String)
      return Time.at(time_value) if time_value.is_a?(Numeric) && time_value > 0
    rescue ArgumentError
      # Swallow invalid dates. Better to loose some observability
      # than bring all background processing down because of a date
      # formatting bug in a client
    end
    private_class_method :convert_to_time
  end
end
