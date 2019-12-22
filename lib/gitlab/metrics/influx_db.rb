# frozen_string_literal: true

module Gitlab
  module Metrics
    module InfluxDb
      extend ActiveSupport::Concern
      include Gitlab::Metrics::Methods

      EXECUTION_MEASUREMENT_BUCKETS = [0.001, 0.01, 0.1, 1].freeze

      MUTEX = Mutex.new
      private_constant :MUTEX

      class_methods do
        def influx_metrics_enabled?
          settings[:enabled] || false
        end

        # Prometheus histogram buckets used for arbitrary code measurements

        def settings
          @settings ||= begin
            current_settings = Gitlab::CurrentSettings.current_application_settings

            {
              enabled: current_settings[:metrics_enabled],
              pool_size: current_settings[:metrics_pool_size],
              timeout: current_settings[:metrics_timeout],
              method_call_threshold: current_settings[:metrics_method_call_threshold],
              host: current_settings[:metrics_host],
              port: current_settings[:metrics_port],
              sample_interval: current_settings[:metrics_sample_interval] || 15,
              packet_size: current_settings[:metrics_packet_size] || 1
          }
          end
        end

        def mri?
          RUBY_ENGINE == 'ruby'
        end

        def method_call_threshold
          # This is memoized since this method is called for every instrumented
          # method. Loading data from an external cache on every method call slows
          # things down too much.
          # in milliseconds
          @method_call_threshold ||= settings[:method_call_threshold]
        end

        def submit_metrics(metrics)
          prepared = prepare_metrics(metrics)

          pool&.with do |connection|
            prepared.each_slice(settings[:packet_size]) do |slice|
              connection.write_points(slice)
            rescue StandardError
            end
          end
        rescue Errno::EADDRNOTAVAIL, SocketError => ex
          Gitlab::EnvironmentLogger.error('Cannot resolve InfluxDB address. GitLab Performance Monitoring will not work.')
          Gitlab::EnvironmentLogger.error(ex)
        end

        def prepare_metrics(metrics)
          metrics.map do |hash|
            new_hash = hash.symbolize_keys

            new_hash[:tags].each do |key, value|
              if value.blank?
                new_hash[:tags].delete(key)
              else
                new_hash[:tags][key] = escape_value(value)
              end
            end

            new_hash
          end
        end

        def escape_value(value)
          value.to_s.gsub('=', '\\=')
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
        def measure(name)
          trans = current_transaction

          return yield unless trans

          real_start = Time.now.to_f
          cpu_start = System.cpu_time

          retval = yield

          cpu_stop = System.cpu_time
          real_stop = Time.now.to_f

          real_time = (real_stop - real_start)
          cpu_time = cpu_stop - cpu_start

          real_duration_seconds = fetch_histogram("gitlab_#{name}_real_duration_seconds".to_sym) do
            docstring "Measure #{name}"
            base_labels Transaction::BASE_LABELS
            buckets EXECUTION_MEASUREMENT_BUCKETS
          end

          real_duration_seconds.observe(trans.labels, real_time)

          cpu_duration_seconds = fetch_histogram("gitlab_#{name}_cpu_duration_seconds".to_sym) do
            docstring "Measure #{name}"
            base_labels Transaction::BASE_LABELS
            buckets EXECUTION_MEASUREMENT_BUCKETS
            with_feature "prometheus_metrics_measure_#{name}_cpu_duration"
          end
          cpu_duration_seconds.observe(trans.labels, cpu_time)

          # InfluxDB stores the _real_time and _cpu_time time values as milliseconds
          trans.increment("#{name}_real_time", real_time.in_milliseconds, false)
          trans.increment("#{name}_cpu_time", cpu_time.in_milliseconds, false)
          trans.increment("#{name}_call_count", 1, false)

          retval
        end

        # Sets the action of the current transaction (if any)
        #
        # action - The name of the action.
        def action=(action)
          trans = current_transaction

          trans&.action = action
        end

        # Tracks an event.
        #
        # See `Gitlab::Metrics::Transaction#add_event` for more details.
        def add_event(*args)
          current_transaction&.add_event(*args)
        end

        # Returns the prefix to use for the name of a series.
        def series_prefix
          @series_prefix ||= Gitlab::Runtime.sidekiq? ? 'sidekiq_' : 'rails_'
        end

        # Allow access from other metrics related middlewares
        def current_transaction
          Transaction.current
        end

        # When enabled this should be set before being used as the usual pattern
        # "@foo ||= bar" is _not_ thread-safe.
        def pool
          if influx_metrics_enabled?
            if @pool.nil?
              MUTEX.synchronize do
                @pool ||= ConnectionPool.new(size: settings[:pool_size], timeout: settings[:timeout]) do
                  host = settings[:host]
                  port = settings[:port]

                  InfluxDB::Client
                    .new(udp: { host: host, port: port })
                end
              end
            end

            @pool
          end
        end
      end
    end
  end
end
