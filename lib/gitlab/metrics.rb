require 'prometheus/client'

module Gitlab
  module Metrics
    extend Gitlab::CurrentSettings

    RAILS_ROOT   = Rails.root.to_s
    METRICS_ROOT = Rails.root.join('lib', 'gitlab', 'metrics').to_s
    PATH_REGEX   = /^#{RAILS_ROOT}\/?/

    def self.settings
      @settings ||= {
        enabled:                    current_application_settings[:metrics_enabled],
        prometheus_metrics_enabled: current_application_settings[:prometheus_metrics_enabled],
        pool_size:                  current_application_settings[:metrics_pool_size],
        timeout:                    current_application_settings[:metrics_timeout],
        method_call_threshold:      current_application_settings[:metrics_method_call_threshold],
        host:                       current_application_settings[:metrics_host],
        port:                       current_application_settings[:metrics_port],
        sample_interval:            current_application_settings[:metrics_sample_interval] || 15,
        packet_size:                current_application_settings[:metrics_packet_size] || 1
      }
    end

    def self.prometheus_metrics_enabled?
      settings[:prometheus_metrics_enabled] || false
    end

    def self.influx_metrics_enabled?
      settings[:enabled] || false
    end

    def self.enabled?
      influx_metrics_enabled? || prometheus_metrics_enabled?
    end

    def self.mri?
      RUBY_ENGINE == 'ruby'
    end

    def self.method_call_threshold
      # This is memoized since this method is called for every instrumented
      # method. Loading data from an external cache on every method call slows
      # things down too much.
      @method_call_threshold ||= settings[:method_call_threshold]
    end

    def self.pool
      @pool
    end

    def self.registry
      @registry ||= ::Prometheus::Client.registry
    end

    def self.counter(name, docstring, base_labels = {})
      dummy_metric || registry.get(name) || registry.counter(name, docstring, base_labels)
    end

    def self.summary(name, docstring, base_labels = {})
      dummy_metric || registry.get(name) || registry.summary(name, docstring, base_labels)
    end

    def self.gauge(name, docstring, base_labels = {})
      dummy_metric || registry.get(name) || registry.gauge(name, docstring, base_labels)
    end

    def self.histogram(name, docstring, base_labels = {}, buckets = Histogram::DEFAULT_BUCKETS)
      dummy_metric || registry.get(name) || registry.histogram(name, docstring, base_labels, buckets)
    end

    def self.dummy_metric
      unless prometheus_metrics_enabled?
        DummyMetric.new
      end
    end

    def self.submit_metrics(metrics)
      prepared = prepare_metrics(metrics)

      if prometheus_metrics_enabled?
        metrics.map do |metric|
          known = [:series, :tags,:values, :timestamp]
          value = metric&.[](:values)&.[](:value)
          handled=  [:rails_gc_statistics]
          if handled.include? metric[:series].to_sym
            next
          end

          if metric.keys.any? {|k| !known.include?(k)} || value.nil?
            print metric
            print "\n"

            {:series=>"rails_gc_statistics", :tags=>{}, :values=>{:count=>0, :heap_allocated_pages=>4245, :heap_sorted_length=>4426, :heap_allocatable_pages=>0, :heap_available_slots=>1730264, :heap_live_slots=>1729935, :heap_free_slots=>329, :heap_final_slots=>0, :heap_marked_slots=>1184216, :heap_swept_slots=>361843, :heap_eden_pages=>4245, :heap_tomb_pages=>0, :total_allocated_pages=>4245, :total_freed_pages=>0, :total_allocated_objects=>15670757, :total_freed_objects=>13940822, :malloc_increase_bytes=>4842256, :malloc_increase_bytes_limit=>29129457, :minor_gc_count=>0, :major_gc_count=>0, :remembered_wb_unprotected_objects=>39905, :remembered_wb_unprotected_objects_limit=>74474, :old_objects=>1078731, :old_objects_limit=>1975860, :oldmalloc_increase_bytes=>4842640, :oldmalloc_increase_bytes_limit=>31509677, :total_time=>0.0}, :timestamp=>1494356175592659968}

            next
          end
          metric_value = gauge(metric[:series].to_sym, metric[:series])
          metric_value.set(metric[:tags], value)
        end
      end

      pool&.with do |connection|
        prepared.each_slice(settings[:packet_size]) do |slice|
          begin
            connection.write_points(slice)
          rescue StandardError
          end
        end
      end
    rescue Errno::EADDRNOTAVAIL, SocketError => ex
      Gitlab::EnvironmentLogger.error('Cannot resolve InfluxDB address. GitLab Performance Monitoring will not work.')
      Gitlab::EnvironmentLogger.error(ex)
    end

    def self.prepare_metrics(metrics)
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

    def self.escape_value(value)
      value.to_s.gsub('=', '\\=')
    end

    # Measures the execution time of a block.
    #
    # Example:
    #
    #     Gitlab::Metrics.measure(:find_by_username_duration) do
    #       User.find_by_username(some_username)
    #     end
    #
    # name - The name of the field to store the execution time in.
    #
    # Returns the value yielded by the supplied block.
    def self.measure(name)
      trans = current_transaction

      return yield unless trans

      real_start = Time.now.to_f
      cpu_start = System.cpu_time

      retval = yield

      cpu_stop = System.cpu_time
      real_stop = Time.now.to_f

      real_time = (real_stop - real_start) * 1000.0
      cpu_time = cpu_stop - cpu_start

      trans.increment("#{name}_real_time", real_time)
      trans.increment("#{name}_cpu_time", cpu_time)
      trans.increment("#{name}_call_count", 1)

      retval
    end

    # Adds a tag to the current transaction (if any)
    #
    # name - The name of the tag to add.
    # value - The value of the tag.
    def self.tag_transaction(name, value)
      trans = current_transaction

      trans&.add_tag(name, value)
    end

    # Sets the action of the current transaction (if any)
    #
    # action - The name of the action.
    def self.action=(action)
      trans = current_transaction

      trans&.action = action
    end

    # Tracks an event.
    #
    # See `Gitlab::Metrics::Transaction#add_event` for more details.
    def self.add_event(*args)
      trans = current_transaction

      trans&.add_event(*args)
    end

    # Returns the prefix to use for the name of a series.
    def self.series_prefix
      @series_prefix ||= Sidekiq.server? ? 'sidekiq_' : 'rails_'
    end

    # Allow access from other metrics related middlewares
    def self.current_transaction
      Transaction.current
    end

    # When enabled this should be set before being used as the usual pattern
    # "@foo ||= bar" is _not_ thread-safe.
    if influx_metrics_enabled?
      @pool = ConnectionPool.new(size: settings[:pool_size], timeout: settings[:timeout]) do
        host = settings[:host]
        port = settings[:port]

        InfluxDB::Client.
          new(udp: { host: host, port: port })
      end
    end
  end
end
