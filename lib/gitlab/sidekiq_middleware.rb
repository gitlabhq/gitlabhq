# frozen_string_literal: true

module Gitlab
  # The SidekiqMiddleware class is responsible for configuring the
  # middleware stacks used in the client and server middlewares
  module SidekiqMiddleware
    class Client
      def self.middlewares
        [
          # ConcurrencyLimit::Resume needs to be first and before Labkit and ConcurrencyLimit::Client
          ::Gitlab::SidekiqMiddleware::ConcurrencyLimit::Resume,
          ::Gitlab::SidekiqMiddleware::WorkerContext::Client, # needs to be before the Labkit middleware
          ::Labkit::Middleware::Sidekiq::Client,
          # Sidekiq Client Middleware should be placed before DuplicateJobs::Client middleware,
          # so we can store WAL location before we deduplicate the job.
          ::Gitlab::Database::LoadBalancing::SidekiqClientMiddleware,
          ::Gitlab::SidekiqMiddleware::PauseControl::Client,
          ::Gitlab::SidekiqMiddleware::ConcurrencyLimit::Client,
          # NOTE: Everything from DuplicateJobs::Client to DuplicateJobs::Server must yield
          # no returning or job interception as it will leave the duplicate job redis key
          # dangling and errorneously deduplicating future jobs until key expires.
          ::Gitlab::SidekiqMiddleware::DuplicateJobs::Client,
          ::Gitlab::SidekiqStatus::ClientMiddleware,
          ::Gitlab::SidekiqMiddleware::AdminMode::Client,
          # Size limiter should be placed at the bottom, but before the metrics middleware
          # NOTE: this raises error after the duplicate jobs middleware but is acceptable
          # since jobs that are too large should not be enqueued.
          ::Gitlab::SidekiqMiddleware::SizeLimiter::Client,
          ::Gitlab::SidekiqMiddleware::ClientMetrics,
          ::Gitlab::SidekiqMiddleware::Identity::Passthrough
        ]
      end

      # The result of this method should be passed to
      # Sidekiq's `config.client_middleware` method
      # eg: `config.client_middleware(&Gitlab::SidekiqMiddleware::Client.configurator)`
      def self.configurator
        ->(chain) do
          middlewares.each { |middleware| chain.add(middleware) }

          if Gitlab::Utils.to_boolean(ENV.fetch('REORDER_DUPLICATE_JOBS_AND_CONCURRENCY_LIMIT_MIDDLEWARE', 'false'))
            chain.insert_after(
              ::Gitlab::SidekiqMiddleware::DuplicateJobs::Client,
              ::Gitlab::SidekiqMiddleware::ConcurrencyLimit::Client)
          end
        end
      end
    end

    class Server
      def self.middlewares(metrics: true, arguments_logger: true, skip_jobs: true)
        [
          # Size limiter should be placed at the top
          ::Gitlab::SidekiqMiddleware::SizeLimiter::Server,
          ::Gitlab::SidekiqMiddleware::ShardAwarenessValidator,
          ::Gitlab::SidekiqMiddleware::Monitor,

          # Labkit wraps the job in the `Labkit::Context` resurrected from
          # the job-hash. We need properties from the context for
          # recording metrics, so this needs to be before
          # `::Gitlab::SidekiqMiddleware::ServerMetrics` (if we're using
          # that).
          ::Labkit::Middleware::Sidekiq::Server,
          ::Gitlab::SidekiqMiddleware::RequestStoreMiddleware,

          ::Gitlab::QueryLimiting.enabled_for_env? ? ::Gitlab::QueryLimiting::SidekiqMiddleware : nil,

          metrics ? ::Gitlab::SidekiqMiddleware::ServerMetrics : nil,

          arguments_logger ? ::Gitlab::SidekiqMiddleware::ArgumentsLogger : nil,
          ::Gitlab::SidekiqMiddleware::ExtraDoneLogMetadata,
          ::Gitlab::SidekiqMiddleware::BatchLoader,
          ::Gitlab::SidekiqMiddleware::InstrumentationLogger,
          ::Gitlab::SidekiqMiddleware::SetIpAddress,
          ::Gitlab::SidekiqMiddleware::AdminMode::Server,
          ::Gitlab::SidekiqMiddleware::QueryAnalyzer,
          ::Gitlab::SidekiqVersioning::Middleware,
          ::Gitlab::SidekiqStatus::ServerMiddleware,
          ::Gitlab::SidekiqMiddleware::WorkerContext::Server,
          ::ClickHouse::MigrationSupport::SidekiqMiddleware,
          # DuplicateJobs::Server should be placed at the bottom, but before the SidekiqServerMiddleware,
          # so we can compare the latest WAL location against replica
          # NOTE: Everything from DuplicateJobs::Client to DuplicateJobs::Server must yield
          # no returning or job interception as it will leave the duplicate job redis key
          # dangling and errorneously deduplicating future jobs until key expires.
          # Any middlewares after DuplicateJobs::Server can return/intercept jobs.
          ::Gitlab::SidekiqMiddleware::DuplicateJobs::Server,
          ::Gitlab::SidekiqMiddleware::PauseControl::Server,
          ::Gitlab::SidekiqMiddleware::Throttling::Server,
          ::Gitlab::SidekiqMiddleware::ConcurrencyLimit::Server,
          skip_jobs ? ::Gitlab::SidekiqMiddleware::SkipJobs : nil,
          ::Gitlab::Database::LoadBalancing::SidekiqServerMiddleware,
          ::Gitlab::SidekiqMiddleware::ResourceUsageLimit::Server,
          ::Gitlab::SidekiqMiddleware::Identity::Restore
        ].compact
      end

      # The result of this method should be passed to
      # Sidekiq's `config.server_middleware` method
      # eg: `config.server_middleware(&Gitlab::SidekiqMiddleware::Server.configurator)`
      def self.configurator(metrics: true, arguments_logger: true, skip_jobs: true)
        ->(chain) do
          middlewares(metrics: metrics, arguments_logger: arguments_logger, skip_jobs: skip_jobs).each do |middleware|
            chain.add(middleware)
          end

          if Gitlab::Utils.to_boolean(ENV.fetch('REORDER_DUPLICATE_JOBS_AND_CONCURRENCY_LIMIT_MIDDLEWARE', 'false'))
            chain.insert_before(
              ::Gitlab::SidekiqMiddleware::DuplicateJobs::Server,
              ::Gitlab::SidekiqMiddleware::ConcurrencyLimit::Server)
          end

          ::Gitlab::SidekiqMiddleware::ServerMetrics.initialize_process_metrics if metrics
        end
      end
    end
  end
end

Gitlab::SidekiqMiddleware::Client.prepend_mod
Gitlab::SidekiqMiddleware::Server.prepend_mod
