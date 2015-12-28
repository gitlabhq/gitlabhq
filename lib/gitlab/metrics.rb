module Gitlab
  module Metrics
    RAILS_ROOT   = Rails.root.to_s
    METRICS_ROOT = Rails.root.join('lib', 'gitlab', 'metrics').to_s
    PATH_REGEX   = /^#{RAILS_ROOT}\/?/

    # Returns the current settings, ensuring we _always_ have a default set of
    # metrics settings (even during tests, when the migrations are lacking,
    # etc). This ensures the application is able to boot up even when the
    # migrations have not been executed.
    def self.settings
      ApplicationSetting.current || {
        metrics_pool_size:             16,
        metrics_timeout:               10,
        metrics_enabled:               false,
        metrics_method_call_threshold: 10
      }
    end

    def self.pool_size
      settings[:metrics_pool_size]
    end

    def self.timeout
      settings[:metrics_timeout]
    end

    def self.enabled?
      settings[:metrics_enabled]
    end

    def self.mri?
      RUBY_ENGINE == 'ruby'
    end

    def self.method_call_threshold
      # This is memoized since this method is called for every instrumented
      # method. Loading data from an external cache on every method call slows
      # things down too much.
      @method_call_threshold ||= settings[:metrics_method_call_threshold]
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

    @hostname = Socket.gethostname

    # When enabled this should be set before being used as the usual pattern
    # "@foo ||= bar" is _not_ thread-safe.
    if enabled?
      @pool = ConnectionPool.new(size: pool_size, timeout: timeout) do
        host = settings[:metrics_host]
        db   = settings[:metrics_database]
        user = settings[:metrics_username]
        pw   = settings[:metrics_password]

        InfluxDB::Client.new(db, host: host, username: user, password: pw)
      end
    end
  end
end
