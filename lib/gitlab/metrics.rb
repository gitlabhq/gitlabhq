# frozen_string_literal: true

module Gitlab
  module Metrics
    include Gitlab::Metrics::Prometheus

    EXECUTION_MEASUREMENT_BUCKETS = [0.001, 0.01, 0.1, 1].freeze

    @error = false

    def self.enabled?
      prometheus_metrics_enabled?
    end

    def self.error?
      @error
    end

    def self.record_duration_for_status?(status)
      status.to_i.between?(200, 499)
    end

    # Tracks an event.
    #
    # See `Gitlab::Metrics::Transaction#add_event` for more details.
    def self.add_event(*args)
      current_transaction&.add_event(*args)
    end

    # Allow access from other metrics related middlewares
    def self.current_transaction
      Transaction.current
    end

    # Returns the prefix to use for the name of a series.
    def self.series_prefix
      @series_prefix ||= Gitlab::Runtime.sidekiq? ? 'sidekiq_' : 'rails_'
    end

    def self.settings
      @settings ||= begin
        current_settings = Gitlab::CurrentSettings.current_application_settings

        {

          method_call_threshold: current_settings[:metrics_method_call_threshold]

        }
      end
    end

    def self.method_call_threshold
      # This is memoized since this method is called for every instrumented
      # method. Loading data from an external cache on every method call slows
      # things down too much.
      # in milliseconds
      @method_call_threshold ||= settings[:method_call_threshold]
    end

    # Measures the execution time of a block.
    #
    # Example:
    #
    #     Gitlab::Metrics.measure(:find_by_username_duration) do
    #       UserFinder.new(some_username).find_by_username
    #     end
    #
    # name - The name of the field to store the execution time in.
    #
    # Returns the value yielded by the supplied block.
    def self.measure(name)
      trans = current_transaction

      return yield unless trans

      real_start = System.monotonic_time
      cpu_start = System.cpu_time

      retval = yield

      cpu_stop = System.cpu_time
      real_stop = System.monotonic_time

      real_time = (real_stop - real_start)
      cpu_time = cpu_stop - cpu_start

      trans.observe("gitlab_#{name}_real_duration_seconds".to_sym, real_time) do
        docstring "Measure #{name}"
        buckets EXECUTION_MEASUREMENT_BUCKETS
      end

      trans.observe("gitlab_#{name}_cpu_duration_seconds".to_sym, cpu_time) do
        docstring "Measure #{name}"
        buckets EXECUTION_MEASUREMENT_BUCKETS
        with_feature "prometheus_metrics_measure_#{name}_cpu_duration"
      end

      retval
    end
  end
end
