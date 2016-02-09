if Gitlab::Metrics.enabled?
  require 'influxdb'
  require 'connection_pool'
  require 'method_source'

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

  # This instruments all methods residing in app/models that (appear to) use any
  # of the ActiveRecord methods. This has to take place _after_ initializing as
  # for some unknown reason calling eager_load! earlier breaks Devise.
  Gitlab::Application.config.after_initialize do
    Rails.application.eager_load!

    models = Rails.root.join('app', 'models').to_s

    regex = Regexp.union(
      ActiveRecord::Querying.public_instance_methods(false).map(&:to_s)
    )

    Gitlab::Metrics::Instrumentation.
      instrument_class_hierarchy(ActiveRecord::Base) do |klass, method|
        # Instrumenting the ApplicationSetting class can lead to an infinite
        # loop. Since the data is cached any way we don't really need to
        # instrument it.
        if klass == ApplicationSetting
          false
        else
          loc = method.source_location

          loc && loc[0].start_with?(models) && method.source =~ regex
        end
      end
  end

  Gitlab::Metrics::Instrumentation.configure do |config|
    config.instrument_instance_methods(Gitlab::Shell)

    config.instrument_methods(Gitlab::Git)

    Gitlab::Git.constants.each do |name|
      const = Gitlab::Git.const_get(name)

      next unless const.is_a?(Module)

      config.instrument_methods(const)
      config.instrument_instance_methods(const)
    end

    Dir[Rails.root.join('app', 'finders', '*.rb')].each do |path|
      const = File.basename(path, '.rb').camelize.constantize

      config.instrument_instance_methods(const)
    end

    [
      :Blame, :Branch, :BranchCollection, :Blob, :Commit, :Diff, :Repository,
      :Tag, :TagCollection, :Tree
    ].each do |name|
      const = Rugged.const_get(name)

      config.instrument_methods(const)
      config.instrument_instance_methods(const)
    end
  end

  GC::Profiler.enable

  Gitlab::Metrics::Sampler.new.start
end
