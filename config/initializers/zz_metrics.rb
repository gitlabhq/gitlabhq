# frozen_string_literal: true

# This file was prefixed with zz_ because we want to load it the last!
# See: https://gitlab.com/gitlab-org/gitlab-foss/issues/55611
if Gitlab::Metrics.enabled? && Gitlab::Runtime.application?
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

    config.middleware.move_after Gitlab::Metrics::RackMiddleware,
      Gitlab::EtagCaching::Middleware

    config.middleware.use(Gitlab::Metrics::ElasticsearchRackMiddleware)
  end

  Gitlab::Metrics.initialize_slis!

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

  Rails.application.configure do
    config.after_initialize do
      Metrics::PatchedFilesWorker.perform_async
    end
  end
end
