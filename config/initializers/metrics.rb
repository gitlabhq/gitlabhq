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
    config.middleware.use(Gitlab::Middleware::RailsQueueDuration)
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

    # Path to search => prefix to strip from constant
    paths_to_instrument = {
      ['app', 'finders']                    => ['app', 'finders'],
      ['app', 'mailers', 'emails']          => ['app', 'mailers'],
      ['app', 'services', '**']             => ['app', 'services'],
      ['lib', 'gitlab', 'diff']             => ['lib'],
      ['lib', 'gitlab', 'email', 'message'] => ['lib']
    }

    paths_to_instrument.each do |(path, prefix)|
      prefix = Rails.root.join(*prefix)

      Dir[Rails.root.join(*path + ['*.rb'])].each do |file_path|
        path = Pathname.new(file_path).relative_path_from(prefix)
        const = path.to_s.sub('.rb', '').camelize.constantize

        config.instrument_methods(const)
        config.instrument_instance_methods(const)
      end
    end

    config.instrument_methods(Premailer::Adapter::Nokogiri)
    config.instrument_instance_methods(Premailer::Adapter::Nokogiri)

    [
      :Blame, :Branch, :BranchCollection, :Blob, :Commit, :Diff, :Repository,
      :Tag, :TagCollection, :Tree
    ].each do |name|
      const = Rugged.const_get(name)

      config.instrument_methods(const)
      config.instrument_instance_methods(const)
    end

    # Instruments all Banzai filters and reference parsers
    {
      Filter: Rails.root.join('lib', 'banzai', 'filter', '*.rb'),
      ReferenceParser: Rails.root.join('lib', 'banzai', 'reference_parser', '*.rb')
    }.each do |const_name, path|
      Dir[path].each do |file|
        klass = File.basename(file, File.extname(file)).camelize
        const = Banzai.const_get(const_name).const_get(klass)

        config.instrument_methods(const)
        config.instrument_instance_methods(const)
      end
    end

    config.instrument_methods(Banzai::Renderer)
    config.instrument_methods(Banzai::Querying)

    config.instrument_instance_methods(Banzai::ObjectRenderer)
    config.instrument_instance_methods(Banzai::Redactor)
    config.instrument_methods(Banzai::NoteRenderer)

    [Issuable, Mentionable, Participable].each do |klass|
      config.instrument_instance_methods(klass)
      config.instrument_instance_methods(klass::ClassMethods)
    end

    config.instrument_methods(Gitlab::ReferenceExtractor)
    config.instrument_instance_methods(Gitlab::ReferenceExtractor)

    # Instrument the classes used for checking if somebody has push access.
    config.instrument_instance_methods(Gitlab::GitAccess)
    config.instrument_instance_methods(Gitlab::GitAccessWiki)

    config.instrument_instance_methods(API::Helpers)

    config.instrument_instance_methods(RepositoryCheck::SingleRepositoryWorker)

    config.instrument_instance_methods(Rouge::Plugins::Redcarpet)
    config.instrument_instance_methods(Rouge::Formatters::HTMLGitlab)

    config.instrument_methods(Rinku)
  end

  GC::Profiler.enable

  Gitlab::Metrics::Sampler.new.start

  Gitlab::Metrics::Instrumentation.configure do |config|
    config.instrument_instance_methods(Gitlab::InsecureKeyFingerprint)
  end

  module TrackNewRedisConnections
    def connect(*args)
      val = super

      if current_transaction = Gitlab::Metrics::Transaction.current
        current_transaction.increment(:new_redis_connections, 1)
      end

      val
    end
  end

  class ::Redis::Client
    prepend TrackNewRedisConnections
  end
end
