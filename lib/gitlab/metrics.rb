module Gitlab
  module Metrics
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

    def self.last_relative_application_frame
      root    = Rails.root.to_s
      metrics = Rails.root.join('lib', 'gitlab', 'metrics').to_s

      frame = caller_locations.find do |l|
        l.path.start_with?(root) && !l.path.start_with?(metrics)
      end

      if frame
        return frame.path.gsub(/^#{Rails.root.to_s}\/?/, ''), frame.lineno
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
