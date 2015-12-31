module Gitlab
  module Metrics
    extend Gitlab::CurrentSettings

    RAILS_ROOT   = Rails.root.to_s
    METRICS_ROOT = Rails.root.join('lib', 'gitlab', 'metrics').to_s
    PATH_REGEX   = /^#{RAILS_ROOT}\/?/

    def self.settings
      @settings ||= {
        enabled:               current_application_settings[:metrics_enabled],
        pool_size:             current_application_settings[:metrics_pool_size],
        timeout:               current_application_settings[:metrics_timeout],
        method_call_threshold: current_application_settings[:metrics_method_call_threshold],
        host:                  current_application_settings[:metrics_host],
        username:              current_application_settings[:metrics_username],
        password:              current_application_settings[:metrics_password],
        port:                  current_application_settings[:metrics_port]
      }
    end

    def self.enabled?
      settings[:enabled] || false
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

    def self.hostname
      @hostname
    end

    # Returns a relative path and line number based on the last application call
    # frame.
    def self.last_relative_application_frame
      frame = caller_locations.find do |l|
        l.path.start_with?(RAILS_ROOT) && !l.path.start_with?(METRICS_ROOT)
      end

      if frame
        return frame.path.sub(PATH_REGEX, ''), frame.lineno
      else
        return nil, nil
      end
    end

    def self.submit_metrics(metrics)
      prepared = prepare_metrics(metrics)

      pool.with do |connection|
        prepared.each do |metric|
          begin
            connection.write_points([metric])
          rescue StandardError
          end
        end
      end
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

    @hostname = Socket.gethostname

    # When enabled this should be set before being used as the usual pattern
    # "@foo ||= bar" is _not_ thread-safe.
    if enabled?
      @pool = ConnectionPool.new(size: settings[:pool_size], timeout: settings[:timeout]) do
        host = settings[:host]
        user = settings[:username]
        pw   = settings[:password]
        port = settings[:port]

        InfluxDB::Client.
          new(udp: { host: host, port: port }, username: user, password: pw)
      end
    end
  end
end
