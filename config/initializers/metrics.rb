if Gitlab::Metrics.enabled?
  require 'pathname'
  require 'influxdb'
  require 'connection_pool'
  require 'method_source'

  # These are manually require'd so the classes are registered properly with
  # ActiveSupport.
  require 'gitlab/metrics/subscribers/action_view'
  require 'gitlab/metrics/subscribers/active_record'
  require 'gitlab/metrics/subscribers/rails_cache'

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

    # Instruments all Banzai filters
    Dir[Rails.root.join('lib', 'banzai', 'filter', '*.rb')].each do |file|
      klass = File.basename(file, File.extname(file)).camelize
      const = Banzai::Filter.const_get(klass)

      config.instrument_methods(const)
      config.instrument_instance_methods(const)
    end

    config.instrument_methods(Banzai::Renderer)
    config.instrument_methods(Banzai::Querying)

    [Issuable, Mentionable, Participable].each do |klass|
      config.instrument_instance_methods(klass)
      config.instrument_instance_methods(klass::ClassMethods)
    end

    config.instrument_methods(Gitlab::ReferenceExtractor)
    config.instrument_instance_methods(Gitlab::ReferenceExtractor)

    # Instrument all service classes
    services = Rails.root.join('app', 'services')

    Dir[services.join('**', '*.rb')].each do |file_path|
      path = Pathname.new(file_path).relative_path_from(services)
      const = path.to_s.sub('.rb', '').camelize.constantize

      config.instrument_methods(const)
      config.instrument_instance_methods(const)
    end

    # Instrument the classes used for checking if somebody has push access.
    config.instrument_instance_methods(Gitlab::GitAccess)
    config.instrument_instance_methods(Gitlab::GitAccessWiki)
  end

  GC::Profiler.enable

  Gitlab::Metrics::Sampler.new.start
end
