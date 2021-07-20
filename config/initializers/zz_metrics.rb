# frozen_string_literal: true

# This file was prefixed with zz_ because we want to load it the last!
# See: https://gitlab.com/gitlab-org/gitlab-foss/issues/55611

# Autoload all classes that we want to instrument, and instrument the methods we
# need. This takes the Gitlab::Metrics::Instrumentation module as an argument so
# that we can stub it for testing, as it is only called when metrics are
# enabled.
#
# rubocop:disable Metrics/AbcSize
def instrument_classes(instrumentation)
  return if ENV['STATIC_VERIFICATION']

  instrumentation.instrument_instance_methods(Gitlab::Shell)

  instrumentation.instrument_methods(Gitlab::Git)

  Gitlab::Git.constants.each do |name|
    const = Gitlab::Git.const_get(name, false)

    next unless const.is_a?(Module)

    instrumentation.instrument_methods(const)
    instrumentation.instrument_instance_methods(const)
  end

  # Path to search => prefix to strip from constant
  paths_to_instrument = {
    %w(app finders)                => %w(app finders),
    %w(app mailers emails)         => %w(app mailers),
    # Don't instrument `app/services/concerns`
    # It contains modules that are included in the services.
    # The services themselves are instrumented so the methods from the modules
    # are included.
    %w(app services [^concerns]**) => %w(app services),
    %w(lib gitlab conflicts)       => ['lib'],
    %w(lib gitlab email message)   => ['lib'],
    %w(lib gitlab checks)          => ['lib']
  }

  paths_to_instrument.each do |(path, prefix)|
    prefix = Rails.root.join(*prefix)

    Dir[Rails.root.join(*path + ['*.rb'])].each do |file_path|
      path = Pathname.new(file_path).relative_path_from(prefix)
      const = path.to_s.sub('.rb', '').camelize.constantize

      instrumentation.instrument_methods(const)
      instrumentation.instrument_instance_methods(const)
    end
  end

  instrumentation.instrument_methods(Premailer::Adapter::Nokogiri)
  instrumentation.instrument_instance_methods(Premailer::Adapter::Nokogiri)

  instrumentation.instrument_methods(Banzai::Renderer)
  instrumentation.instrument_methods(Banzai::Querying)

  instrumentation.instrument_instance_methods(Banzai::ObjectRenderer)
  instrumentation.instrument_instance_methods(Banzai::ReferenceRedactor)

  [Issuable, Mentionable, Participable].each do |klass|
    instrumentation.instrument_instance_methods(klass)
    instrumentation.instrument_instance_methods(klass::ClassMethods)
  end

  instrumentation.instrument_methods(Gitlab::ReferenceExtractor)
  instrumentation.instrument_instance_methods(Gitlab::ReferenceExtractor)

  # Instrument the classes used for checking if somebody has push access.
  instrumentation.instrument_instance_methods(Gitlab::GitAccess)
  instrumentation.instrument_instance_methods(Gitlab::GitAccessWiki)

  instrumentation.instrument_instance_methods(API::Helpers)

  instrumentation.instrument_instance_methods(RepositoryCheck::SingleRepositoryWorker)

  instrumentation.instrument_instance_methods(Rouge::Formatters::HTMLGitlab)

  [:XML, :HTML].each do |namespace|
    namespace_mod = Nokogiri.const_get(namespace, false)

    instrumentation.instrument_methods(namespace_mod)
    instrumentation.instrument_methods(namespace_mod::Document)
  end

  instrumentation.instrument_methods(Rinku)
  instrumentation.instrument_instance_methods(Repository)

  instrumentation.instrument_methods(Gitlab::Highlight)
  instrumentation.instrument_instance_methods(Gitlab::Highlight)
  instrumentation.instrument_instance_method(Gitlab::Ci::Config::Yaml::Tags::Resolver, :to_hash)

  Gitlab.ee do
    instrumentation.instrument_instance_methods(Elastic::Latest::GitInstanceProxy)
    instrumentation.instrument_instance_methods(Elastic::Latest::GitClassProxy)

    instrumentation.instrument_instance_methods(Search::GlobalService)
    instrumentation.instrument_instance_methods(Search::ProjectService)

    instrumentation.instrument_instance_methods(Gitlab::Elastic::SearchResults)
    instrumentation.instrument_instance_methods(Gitlab::Elastic::ProjectSearchResults)
    instrumentation.instrument_instance_methods(Gitlab::Elastic::Indexer)
    instrumentation.instrument_instance_methods(Gitlab::Elastic::SnippetSearchResults)
    instrumentation.instrument_instance_methods(Gitlab::Elastic::Helper)

    instrumentation.instrument_instance_methods(Elastic::ApplicationVersionedSearch)
    instrumentation.instrument_instance_methods(Elastic::ProjectsSearch)
    instrumentation.instrument_instance_methods(Elastic::RepositoriesSearch)
    instrumentation.instrument_instance_methods(Elastic::SnippetsSearch)
    instrumentation.instrument_instance_methods(Elastic::WikiRepositoriesSearch)

    instrumentation.instrument_instance_methods(Gitlab::BitbucketImport::Importer)
    instrumentation.instrument_instance_methods(Bitbucket::Connection)

    instrumentation.instrument_instance_methods(Geo::RepositorySyncWorker)
  end

  # This is a Rails scope so we have to instrument it manually.
  instrumentation.instrument_method(Project, :visible_to_user)

  # Needed for https://gitlab.com/gitlab-org/gitlab-foss/issues/30224#note_32306159
  instrumentation.instrument_instance_method(MergeRequestDiff, :load_commits)
end
# rubocop:enable Metrics/AbcSize

# With prometheus enabled by default this breaks all specs
# that stubs methods using `any_instance_of` for the models reloaded here.
#
# We should deprecate the usage of `any_instance_of` in the future
# check: https://github.com/rspec/rspec-mocks#settings-mocks-or-stubs-on-any-instance-of-a-class
#
# Related issue: https://gitlab.com/gitlab-org/gitlab-foss/issues/33587
#
# In development mode, we turn off eager loading when we're running
# `rails generate migration` because eager loading short-circuits the
# loading of our custom migration templates.
if Gitlab::Metrics.enabled? && !Rails.env.test? && !(Rails.env.development? && defined?(Rails::Generators))
  require 'pathname'
  require 'connection_pool'
  require 'method_source'

  # These are manually require'd so the classes are registered properly with
  # ActiveSupport.
  require_dependency 'gitlab/metrics/subscribers/action_cable'
  require_dependency 'gitlab/metrics/subscribers/action_view'
  require_dependency 'gitlab/metrics/subscribers/active_record'
  require_dependency 'gitlab/metrics/subscribers/rails_cache'

  Gitlab::Application.configure do |config|
    # We want to track certain metrics during the Load Balancing host resolving process.
    # Because of that, we need to have metrics code available earlier for Load Balancing.
    if Gitlab::Database::LoadBalancing.enable?
      config.middleware.insert_before Gitlab::Database::LoadBalancing::RackMiddleware,
        Gitlab::Metrics::RackMiddleware
    else
      config.middleware.use(Gitlab::Metrics::RackMiddleware)
    end

    config.middleware.use(Gitlab::Middleware::RailsQueueDuration)
    config.middleware.use(Gitlab::Metrics::ElasticsearchRackMiddleware)
  end

  # This instruments all methods residing in app/models that (appear to) use any
  # of the ActiveRecord methods. This has to take place _after_ initializing as
  # for some unknown reason calling eager_load! earlier breaks Devise.
  Gitlab::Application.config.after_initialize do
    # We should move all the logic of this file to somewhere else
    # and require it after `Rails.application.initialize!` in `environment.rb` file.
    models_path = Rails.root.join('app', 'models').to_s

    Dir.glob("**/*.rb", base: models_path).sort.each do |file|
      require_dependency file
    end

    regex = Regexp.union(
      ActiveRecord::Querying.public_instance_methods(false).map(&:to_s)
    )

    Gitlab::Metrics::Instrumentation
      .instrument_class_hierarchy(ActiveRecord::Base) do |klass, method|
        # Instrumenting the ApplicationSetting class can lead to an infinite
        # loop. Since the data is cached any way we don't really need to
        # instrument it.
        if klass == ApplicationSetting
          false
        else
          loc = method.source_location

          loc && loc[0].start_with?(models_path) && method.source =~ regex
        end
      end

    # Ability is in app/models, is not an ActiveRecord model, but should still
    # be instrumented.
    Gitlab::Metrics::Instrumentation.instrument_methods(Ability)
  end

  Gitlab::Metrics::Instrumentation.configure do |config|
    instrument_classes(config)
  end

  GC::Profiler.enable

  module TrackNewRedisConnections
    def connect(*args)
      val = super

      if current_transaction = ::Gitlab::Metrics::Transaction.current
        current_transaction.increment(:gitlab_transaction_new_redis_connections_total, 1)
      end

      val
    end
  end

  class ::Redis::Client
    prepend TrackNewRedisConnections
  end

  Labkit::NetHttpPublisher.labkit_prepend!
  Labkit::ExconPublisher.labkit_prepend!
  Labkit::HTTPClientPublisher.labkit_prepend!
end
