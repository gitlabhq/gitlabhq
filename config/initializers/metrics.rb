if Gitlab::Metrics.enabled?
  require 'influxdb'
  require 'socket'
  require 'connection_pool'

  # These are manually require'd so the classes are registered properly with
  # ActiveSupport.
  require 'gitlab/metrics/subscribers/action_view'
  require 'gitlab/metrics/subscribers/active_record'

  Gitlab::Application.configure do |config|
    config.middleware.use(Gitlab::Metrics::RackMiddleware)
  end

  Sidekiq.configure_server do |config|
    config.server_middleware do |chain|
      chain.add Gitlab::Metrics::SidekiqMiddleware
    end
  end

  Gitlab::Metrics::Instrumentation.configure do |config|
    config.instrument_instance_methods(Gitlab::Shell)

    config.instrument_methods(Gitlab::Git)

    Gitlab::Git.constants.each do |name|
      const = Gitlab::Git.const_get(name)

      config.instrument_methods(const) if const.is_a?(Module)
    end
  end

  GC::Profiler.enable

  Gitlab::Metrics::Sampler.new.start
end
