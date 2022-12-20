# frozen_string_literal: true

# This file was prefixed with zz_ because we want to load it the last!
# See: https://gitlab.com/gitlab-org/gitlab-foss/issues/55611

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

  # These are manually require'd so the classes are registered properly with
  # ActiveSupport.
  require_dependency 'gitlab/metrics/subscribers/action_cable'
  require_dependency 'gitlab/metrics/subscribers/action_view'
  require_dependency 'gitlab/metrics/subscribers/active_record'
  require_dependency 'gitlab/metrics/subscribers/rails_cache'
  require_dependency 'gitlab/metrics/subscribers/ldap'

  Gitlab::Application.configure do |config|
    # We want to track certain metrics during the Load Balancing host resolving process.
    # Because of that, we need to have metrics code available earlier for Load Balancing.
    config.middleware.insert_before Gitlab::Database::LoadBalancing::RackMiddleware,
      Gitlab::Metrics::RackMiddleware

    config.middleware.insert_before Gitlab::Database::LoadBalancing::RackMiddleware,
                                   Gitlab::Middleware::RailsQueueDuration

    config.middleware.use(Gitlab::Metrics::ElasticsearchRackMiddleware)
  end

  if Gitlab::Runtime.puma?
    Gitlab::Metrics::RequestsRackMiddleware.initialize_metrics
    Gitlab::Metrics::GlobalSearchSlis.initialize_slis!
  elsif Gitlab::Runtime.sidekiq?
    Gitlab::Metrics::GlobalSearchIndexingSlis.initialize_slis! if Gitlab.ee?
    Gitlab::Metrics::LooseForeignKeysSlis.initialize_slis!
  end

  GC::Profiler.enable

  module TrackNewRedisConnections
    def connect(*args)
      val = super

      if current_transaction = (::Gitlab::Metrics::WebTransaction.current || ::Gitlab::Metrics::BackgroundTransaction.current)
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
