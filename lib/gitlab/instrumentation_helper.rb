# frozen_string_literal: true

module Gitlab
  module InstrumentationHelper
    extend self

    KEYS = %i(gitaly_calls gitaly_duration_s rugged_calls rugged_duration_s redis_calls redis_duration_s).freeze

    def add_instrumentation_data(payload)
      gitaly_calls = Gitlab::GitalyClient.get_request_count

      if gitaly_calls > 0
        payload[:gitaly_calls] = gitaly_calls
        payload[:gitaly_duration_s] = Gitlab::GitalyClient.query_time.round(2)
      end

      rugged_calls = Gitlab::RuggedInstrumentation.query_count

      if rugged_calls > 0
        payload[:rugged_calls] = rugged_calls
        payload[:rugged_duration_s] = Gitlab::RuggedInstrumentation.query_time.round(2)
      end

      redis_calls = Gitlab::Instrumentation::Redis.get_request_count

      if redis_calls > 0
        payload[:redis_calls] = redis_calls
        payload[:redis_duration_s] = Gitlab::Instrumentation::Redis.query_time.round(2)
      end
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

      # Its possible that if theres clock-skew between two nodes
      # this value may be less than zero. In that event, we record the value
      # as zero.
      [elapsed_by_absolute_time(enqueued_at_time), 0].max.round(2)
    end

    # Calculates the time in seconds, as a float, from
    # the provided start time until now
    #
    # @param [Time] start
    def self.elapsed_by_absolute_time(start)
      (Time.now - start).to_f.round(6)
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
