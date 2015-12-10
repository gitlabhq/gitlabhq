module Gitlab
  module Metrics
    RAILS_ROOT   = Rails.root.to_s
    METRICS_ROOT = Rails.root.join('lib', 'gitlab', 'metrics').to_s
    PATH_REGEX   = /^#{RAILS_ROOT}\/?/

    def self.pool_size
      Settings.metrics['pool_size'] || 16
    end

    def self.timeout
      Settings.metrics['timeout'] || 10
    end

    def self.enabled?
      !!Settings.metrics['enabled']
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
        db   = Settings.metrics['database']
        user = Settings.metrics['username']
        pw   = Settings.metrics['password']

        InfluxDB::Client.new(db, username: user, password: pw)
      end
    end
  end
end
