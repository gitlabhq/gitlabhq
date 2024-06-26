# frozen_string_literal: true

module Gitlab
  # The SidekiqMiddleware class is responsible for configuring the
  # middleware stacks used in the client and server middlewares
  module SidekiqMiddleware
    # The result of this method should be passed to
    # Sidekiq's `config.server_middleware` method
    # eg: `config.server_middleware(&Gitlab::SidekiqMiddleware.server_configurator)`
    def self.server_configurator(metrics: true, arguments_logger: true, skip_jobs: true)
      lambda do |chain|
        # Size limiter should be placed at the top
        chain.add ::Gitlab::SidekiqMiddleware::SizeLimiter::Server
        chain.add ::Gitlab::SidekiqMiddleware::Monitor

        # Labkit wraps the job in the `Labkit::Context` resurrected from
        # the job-hash. We need properties from the context for
        # recording metrics, so this needs to be before
        # `::Gitlab::SidekiqMiddleware::ServerMetrics` (if we're using
        # that).
        chain.add ::Labkit::Middleware::Sidekiq::Server

        if metrics
          chain.add ::Gitlab::SidekiqMiddleware::ServerMetrics

          ::Gitlab::SidekiqMiddleware::ServerMetrics.initialize_process_metrics
        end

        chain.add ::Gitlab::SidekiqMiddleware::ArgumentsLogger if arguments_logger
        chain.add ::Gitlab::SidekiqMiddleware::RequestStoreMiddleware
        chain.add ::Gitlab::SidekiqMiddleware::ExtraDoneLogMetadata
        chain.add ::Gitlab::SidekiqMiddleware::BatchLoader
        chain.add ::Gitlab::SidekiqMiddleware::InstrumentationLogger
        chain.add ::Gitlab::SidekiqMiddleware::AdminMode::Server
        chain.add ::Gitlab::SidekiqMiddleware::QueryAnalyzer
        chain.add ::Gitlab::SidekiqVersioning::Middleware
        chain.add ::Gitlab::SidekiqStatus::ServerMiddleware
        chain.add ::Gitlab::SidekiqMiddleware::WorkerContext::Server
        chain.add ::Gitlab::SidekiqMiddleware::PauseControl::Server
        chain.add ::ClickHouse::MigrationSupport::SidekiqMiddleware
        chain.add ::Gitlab::SidekiqMiddleware::ConcurrencyLimit::Server
        # DuplicateJobs::Server should be placed at the bottom, but before the SidekiqServerMiddleware,
        # so we can compare the latest WAL location against replica
        chain.add ::Gitlab::SidekiqMiddleware::DuplicateJobs::Server
        chain.add ::Gitlab::Database::LoadBalancing::SidekiqServerMiddleware
        chain.add ::Gitlab::SidekiqMiddleware::SkipJobs if skip_jobs
      end
    end

    # The result of this method should be passed to
    # Sidekiq's `config.client_middleware` method
    # eg: `config.client_middleware(&Gitlab::SidekiqMiddleware.client_configurator)`
    def self.client_configurator
      lambda do |chain|
        chain.add ::Gitlab::SidekiqMiddleware::WorkerContext::Client # needs to be before the Labkit middleware
        chain.add ::Labkit::Middleware::Sidekiq::Client
        # Sidekiq Client Middleware should be placed before DuplicateJobs::Client middleware,
        # so we can store WAL location before we deduplicate the job.
        chain.add ::Gitlab::Database::LoadBalancing::SidekiqClientMiddleware
        chain.add ::Gitlab::SidekiqMiddleware::PauseControl::Client
        chain.add ::Gitlab::SidekiqMiddleware::ConcurrencyLimit::Client
        chain.add ::Gitlab::SidekiqMiddleware::DuplicateJobs::Client
        chain.add ::Gitlab::SidekiqStatus::ClientMiddleware
        chain.add ::Gitlab::SidekiqMiddleware::AdminMode::Client
        # Size limiter should be placed at the bottom, but before the metrics middleware
        chain.add ::Gitlab::SidekiqMiddleware::SizeLimiter::Client
        chain.add ::Gitlab::SidekiqMiddleware::ClientMetrics
      end
    end
  end
end

Gitlab::SidekiqMiddleware.prepend_mod
