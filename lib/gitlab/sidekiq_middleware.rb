# frozen_string_literal: true

module Gitlab
  # The SidekiqMiddleware class is responsible for configuring the
  # middleware stacks used in the client and server middlewares
  module SidekiqMiddleware
    # The result of this method should be passed to
    # Sidekiq's `config.server_middleware` method
    # eg: `config.server_middleware(&Gitlab::SidekiqMiddleware.server_configurator)`
    def self.server_configurator(metrics: true, arguments_logger: true, memory_killer: true)
      lambda do |chain|
        # Size limiter should be placed at the top
        chain.add ::Gitlab::SidekiqMiddleware::SizeLimiter::Server
        chain.add ::Gitlab::SidekiqMiddleware::Monitor

        if metrics
          chain.add ::Gitlab::SidekiqMiddleware::ServerMetrics

          ::Gitlab::SidekiqMiddleware::ServerMetrics.initialize_process_metrics
        end

        chain.add ::Gitlab::SidekiqMiddleware::ArgumentsLogger if arguments_logger
        chain.add ::Gitlab::SidekiqMiddleware::MemoryKiller if memory_killer
        chain.add ::Gitlab::SidekiqMiddleware::RequestStoreMiddleware
        chain.add ::Gitlab::SidekiqMiddleware::ExtraDoneLogMetadata
        chain.add ::Gitlab::SidekiqMiddleware::BatchLoader
        chain.add ::Labkit::Middleware::Sidekiq::Server
        chain.add ::Gitlab::SidekiqMiddleware::InstrumentationLogger
        chain.add ::Gitlab::Database::LoadBalancing::SidekiqServerMiddleware if load_balancing_enabled?
        chain.add ::Gitlab::SidekiqMiddleware::AdminMode::Server
        chain.add ::Gitlab::SidekiqVersioning::Middleware
        chain.add ::Gitlab::SidekiqStatus::ServerMiddleware
        chain.add ::Gitlab::SidekiqMiddleware::WorkerContext::Server
        chain.add ::Gitlab::SidekiqMiddleware::DuplicateJobs::Server
      end
    end

    # The result of this method should be passed to
    # Sidekiq's `config.client_middleware` method
    # eg: `config.client_middleware(&Gitlab::SidekiqMiddleware.client_configurator)`
    def self.client_configurator
      lambda do |chain|
        chain.add ::Gitlab::SidekiqMiddleware::WorkerContext::Client # needs to be before the Labkit middleware
        chain.add ::Labkit::Middleware::Sidekiq::Client
        chain.add ::Gitlab::SidekiqMiddleware::DuplicateJobs::Client
        chain.add ::Gitlab::SidekiqStatus::ClientMiddleware
        chain.add ::Gitlab::SidekiqMiddleware::AdminMode::Client
        # Size limiter should be placed at the bottom, but before the metrics midleware
        chain.add ::Gitlab::SidekiqMiddleware::SizeLimiter::Client
        chain.add ::Gitlab::SidekiqMiddleware::ClientMetrics
        chain.add ::Gitlab::Database::LoadBalancing::SidekiqClientMiddleware if load_balancing_enabled?
      end
    end

    def self.load_balancing_enabled?
      ::Gitlab::Database::LoadBalancing.enable?
    end
    private_class_method :load_balancing_enabled?
  end
end
